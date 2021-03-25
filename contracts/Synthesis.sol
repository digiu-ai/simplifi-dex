pragma solidity ^0.8.0;
    
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IBridge.sol";
import "./ISyntERC20.sol";
import "./SyntERC20.sol";
import "./ISyntERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
//import "./libraries/Other.sol";

contract Synthesis is Ownable{
    
    address public bridge;
    address public portal;
    mapping (address => address) public representationReal;
    mapping (address => address) public representationSynt;
    uint256 requestCount = 1;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => MintState) public mintingStates;
     
    constructor(address  bridgeAdr)  {
        bridge = bridgeAdr;
    }
    
    modifier onlyBridge {
        require(msg.sender == bridge);
        _;
    }
    
    struct TxState {
    address recepient;
    address chain2address;
    uint256 amount;
    address token;
    address stoken;
    uint256 state;
  }
  
  // 1 - succesful minting
  // 2 - called revert 
  struct MintState {
      uint256 state;
  }
  
    
    
    // SYNT
    function mintSyntheticToken(bytes32 _txID, address _tokenReal, uint256 _amount, address _to) onlyBridge external {
       // mb create syntatic _token if it doesn't exist 
     
       MintState storage mintState = mintingStates[_txID];
        require(mintState.state != 2, "Synt: emergency cashout request called");

        ISyntERC20(representationSynt[_tokenReal]).mint(_to, _amount);
        
        mintState.state = 1;
    }
    
    // can call several times 
    function emergencyCashoutRequest(bytes32 _txID) external{
        MintState storage mintState = mintingStates[_txID];
        require(mintState.state != 1, "Synt: syntatic tokens already minted");
        mintState.state = 2;// close

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('emergencyCashout(bytes32)'))),_txID);
        // TODO add payment by token 
        //IBridge(bridge).transmitRequest(SET_REQUEST_TYPE, IHexstring(util).bytesToHexString(out), Other.toAsciiString(portal));
        IBridge(bridge).transmitRequest(out, portal);
    }
    
    
   
    
    // BURN
    function burn(address _stoken,uint256 _amount, address chain2address) external returns (bytes32 txID) {
        // проверить что при берне больше чем имеется кидается revert 
        ISyntERC20(representationReal[_stoken]).burn(msg.sender, _amount);
     
        txID = keccak256(abi.encodePacked(this, requestCount));

        bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('unsynthesize(bytes32,address,uint256,address)'))),txID, representationReal[_stoken], _amount, chain2address);
        // TODO add payment by token 
        //IBridge(bridge).transmitRequest(SET_REQUEST_TYPE, IHexstring(util).bytesToHexString(out), Other.toAsciiString(portal));
        IBridge(bridge).transmitRequest(out, portal);
        TxState storage txState = requests[txID];
        txState.recepient    = msg.sender;
        txState.chain2address    = chain2address;
        txState.stoken     = _stoken;
        txState.amount     = _amount;
        txState.state = 1;
        
        requestCount += 1;
    }
    
     // TODO uint заменить на другой тип данных
    // вызывается из другого чейна 
    // после того как по транзе был revert 
    function emergencyUnburn(bytes32 _txID) onlyBridge external {
        // проверить были ли деньги по этой транзе 
        // проверить что токены еще не были выданы 
        // выдать токены 
        TxState storage txState = requests[_txID];
        // проверяем что транзакция была и не закрыта 
        require(txState.state == 1 , 'Synt:state not open or tx does not exist');
        txState.state = 2; // close
        ISyntERC20(txState.stoken).mint(txState.recepient, txState.amount);
    }
   


    // utils
   
    
    // TODO only contract can set representations 
    function setRepresentation (address _rtoken, address _stoken) internal {
        representationSynt[_rtoken] = _stoken;
        representationReal[_stoken] = _rtoken;
    }
    
    function createRepresentation(address _rtoken, string memory _stokenName,string memory _stokenSymbol) onlyOwner external{
        address stoken = representationSynt[_rtoken];
        require(stoken == address(0x0), "Synt: token representation already exist");
        SyntERC20 syntToken = new SyntERC20(_stokenName,_stokenSymbol);
        setRepresentation(_rtoken, address(syntToken));
    }
    
    function setPortal(address _adr) onlyOwner external{
      require(portal == address(0x0));
      portal = _adr;
    }
    
    function setBridge(address _adr) onlyOwner external{
      require(bridge == address(0x0));
      bridge = _adr;
    }
}