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

contract test {
    
    address public bridge;
    address public callee;
    address public portal;
    mapping (address => address) public representationReal;
    mapping (address => address) public representationSynt;
    uint256 requestCount = 1;
    mapping (bytes32 => TxState) public requests;
    mapping (bytes32 => MintState) public mintingStates;
    address public syntTokenAddress;
     
    constructor()  {
           SyntERC20 syntToken = new SyntERC20("_stokenName","_stokenSymbol");
           syntTokenAddress = address(syntToken);
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
    function mintSyntheticToken(uint256 _amount, address _to)  external {
       // mb create syntatic _token if it doesn't exist 
     
      
        
        ISyntERC20(syntTokenAddress).mint(_to, _amount);
    
        callee = msg.sender;
    }
    
      function go(uint256 _amount)  external {
       // mb create syntatic _token if it doesn't exist 
       bytes32 _txID =  bytes32(requestCount);
            bytes memory out  = abi.encodeWithSelector(bytes4(keccak256(bytes('mintSyntheticToken(bytes32,address,uint256,address)'))), _txID, address(this), _amount, msg.sender);

            address(this).call(out);
            requestCount +=1;
    }
    
 
    

    // utils
   
    
    // TODO only contract can set representations 
    function setRepresentation (address _rtoken, address _stoken) internal {
        representationSynt[_rtoken] = _stoken;
        representationReal[_stoken] = _rtoken;
    }
    
    
    function setPortal(address _adr)  external{
      portal = _adr;
    }
    
    function setBridge(address _adr)  external{
      bridge = _adr;
    }
}