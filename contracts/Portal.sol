pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/cryptography/ECDSA.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBridge.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
//import "./libraries/Other.sol";

contract Portal is Ownable {

    address public bridge;
    mapping(address => uint) public balanceOf;
    string constant private SET_REQUEST_TYPE = "setRequest";
    address public synthesis;
    uint256 requestCount = 1;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => BurnState) public burningStates;

    constructor(address bridgeAdr)  {
        bridge = bridgeAdr;
    }

    struct TxState {
    address recepient;
    address chain2address;
    uint256 amount;
    address rtoken;
    uint256 state;
    }


  // 1 - succesful burning
  // 2 - called revert
  struct BurnState {
      uint256 state;
  }




 // 1 = отправлена через бридж
 // 2 = токены получены на другом чейне note used here
 // 3 = токены выданы в случае аварии
 //
  modifier onlyBridge {
        require(msg.sender == bridge);
        _;
    }


    // synthesize
    function synthesize(address _token, uint256 _amount, address _chain2address)  external returns (bytes32 txID) {
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        SafeMath.add(balanceOf[_token], _amount);
        // провериють есть ли синтетическа репрезнетация на другом чейне ?
        // создавать ли ее если ее нет - можно ли это забьюзить
        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,address)'))), txID, synthesis, _amount, _chain2address);
        // TODO add payment by token
        // old interface
        //IBridge(bridge).transmitRequest(SET_REQUEST_TYPE, IHexstring(util).bytesToHexString(out), Other.toAsciiString(Synthesis));
        IBridge(bridge).transmitRequest(out, synthesis);
        TxState storage txState = requests[txID];
        txState.recepient    = msg.sender;
        txState.chain2address    = _chain2address;
        txState.rtoken     = _token;
        txState.amount     = _amount;
        txState.state = 1;

        requestCount +=1;
    }

    // вызывается из другого чейна
    // после того как по транзе был revert
    function emergencyCashout(bytes32 _txID) onlyBridge external{
        // проверить были ли деньги по этой транзе
        // проверить что токены еще не были выданы
        // выдать токены
        TxState storage txState = requests[_txID];
        // проверяем что транзакция была и не закрыта
        require(txState.state == 1 , 'Synt:state not open or tx does not exist');
        txState.state = 2; // close
        TransferHelper.safeTransferFrom(txState.rtoken, address(this), txState.recepient, txState.amount);
    }



     // unsynthesize
    function unsynthesize(bytes32 _txID, address _token, uint256 _amount, address _to) onlyBridge external{
        BurnState storage brnState = burningStates[_txID];
        require(brnState.state != 2, "Portal: syntatic tokens emergencyUnburn");

        TransferHelper.safeTransferFrom(_token, address(this), _to, _amount);
        SafeMath.sub(balanceOf[_token], _amount);

        brnState.state = 1;
    }


    // can call several times
    function emergencyUnburnRequest(bytes32 _txID) external {
        BurnState storage brnState = burningStates[_txID];
        require(brnState.state != 1, "Portal: Real tokens already transfered");
        brnState.state = 2;

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('emergencyUnburn(bytes32)'))),_txID);
        // TODO add payment by token
        // old representation
        //IBridge(bridge).transmitRequest(SET_REQUEST_TYPE, IHexstring(util).bytesToHexString(out), Other.toAsciiString(synthesis));
        IBridge(bridge).transmitRequest(out, synthesis);
    }
    
    // utils
    // unused
    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }


    function setSynthesis(address _adr) onlyOwner external {
      //require(synthesis == address(0x0));
      synthesis = _adr;
    }

    function setBridge(address _adr) onlyOwner external{
      //require(bridge == address(0x0));
      bridge = _adr;
    }
}
