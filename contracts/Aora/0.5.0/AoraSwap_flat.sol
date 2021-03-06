
// File: contracts/Ownable.sol

// solium-disable linebreak-style
pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/SafeMath.sol

// solium-disable linebreak-style
pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/IERC20.sol

// solium-disable linebreak-style
pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\AoraSwap.sol

// solium-disable linebreak-style
pragma solidity ^0.5.0;




contract AoraSwap is Ownable {
    using SafeMath for uint256;

    string public name = "AoraSwap";

    mapping (string => bool) events;

    mapping (string => uint) eventsStartTime;

    mapping (address => LockUp[]) addressLockUps;

    string[] public eventNames;

    IERC20 public AoraTgeCoin;

    IERC20 public AoraCoin;

    struct LockUp {
        string eventName;
        uint tokenAmount;
        uint eventStartOffset;
        bool isClaimed;
    }

    constructor(address aoraTge, address aoraCoin) public {
        require(aoraTge != aoraCoin && aoraTge != address(0));
        AoraTgeCoin = IERC20(aoraTge);
        AoraCoin = IERC20(aoraCoin);
    }

    function setAoraTgeCoin(address aoraTgeCoin) public onlyOwner {
        require(aoraTgeCoin != address(0));
        AoraTgeCoin = IERC20(aoraTgeCoin);
    }

    function setAoraCoin(address aoraCoin) public onlyOwner {
        require(aoraCoin != address(0));
        AoraCoin = IERC20(aoraCoin);
    }

    function addEvent(string calldata eventName, uint startTime) external onlyOwner {
        require(!events[eventName], "Event already exists.");
        eventNames.push(eventName);
        events[eventName] = true;
        eventsStartTime[eventName] = startTime;
        emit EventAdded(eventName, startTime);
    }

    function changeEventStartTime(string calldata eventName, uint startTime) external onlyOwner {
        require(events[eventName], "Event doesn't exist.");
        emit EventStartTimeChanged(eventName, eventsStartTime[eventName], startTime);
        eventsStartTime[eventName] = startTime;
    }

    function addLockUpPeriods(
        address who, 
        uint[] memory amounts, 
        uint[] memory eventStartOffsets, 
        string memory eventName
        ) public onlyOwner {
        require(events[eventName], "Event doesn't exist.");
        require(amounts.length == eventStartOffsets.length, "Array lengths of amounts and eventStartOffsets are different.");
        LockUp[] storage lockups = addressLockUps[who];
        for (uint i = 0; i < amounts.length; i++)
            lockups.push(lockUpBuilder(eventName, amounts[i], eventStartOffsets[i]));
    } 

    function claimLockedUpTokens(address who) private {
        uint aoraTgeBalance = AoraTgeCoin.balanceOf(who);
        require(aoraTgeBalance > 0, "Aora TGE balance is 0.");
        
        LockUp[] storage lockups = addressLockUps[who];
        require(lockups.length > 0, "Required more than zero lockups.");
        uint claimAmount = 0;

        for (uint i = 0; i < lockups.length; i++) {
            LockUp storage lockup = lockups[i]; 
            if (!lockup.isClaimed 
            && lockup.eventStartOffset.add(eventsStartTime[lockup.eventName]) <= now) {
                lockup.isClaimed = true;
                claimAmount = claimAmount.add(lockup.tokenAmount);
                emit LockUpClaimed(who, lockup.eventName, lockup.tokenAmount);
            }
        }
        require(claimAmount != 0, "Claim amount is zero.");
        require(aoraTgeBalance >= claimAmount, "Not enough AORA TGE.");
        
        AoraTgeCoin.transferFrom(who, address(0), claimAmount);
        require(AoraCoin.balanceOf(address(this)) > 0, "BALANCE OF AORACOIN is ZERO");
        require(AoraCoin.balanceOf(address(this)) >= claimAmount, "NOT ENOUGH TOKENS TO SEND HERE");
        AoraCoin.transfer(who, claimAmount);
    }

    function userClaimLockedUpTokens() public {
        claimLockedUpTokens(msg.sender);        
    }

    function adminClaimLockedUpTokens(address who) public onlyOwner {
        claimLockedUpTokens(who);
    }

    function doesEventExist(string memory eventName) public view returns(bool) {
        return events[eventName];
    }

    function getEventStartTime(string memory eventName) public view returns(uint256) {
        return eventsStartTime[eventName];
    }

    function getLockedAmount(address who) external view returns(uint) {
        uint lockedAmount = 0;

        LockUp[] memory lockups = addressLockUps[who];
        
        uint i = 0;
        for (; i < lockups.length; i++) // NOTE: Possible optimization, uint length = lockups.length; 
            if (!lockups[i].isClaimed)
                lockedAmount = lockedAmount.add(lockups[i].tokenAmount);
        
        return lockedAmount;
    }

    function getLockedAmountForEvent(address who, string calldata eventName) external view returns(uint) {
        uint lockedAmount = 0;
        
        LockUp[] memory lockups = addressLockUps[who];
        for (uint i = 0; i < lockups.length; i++) 
            if (!lockups[i].isClaimed && compareStrings(lockups[i].eventName, eventName))
                lockedAmount = lockedAmount.add(lockups[i].tokenAmount);
        return lockedAmount;
    }

    function getTimeUntilNextClaim(address who) external view returns(uint) { 
        uint shortestTime = 2**256-1; // max uint256
        LockUp[] memory lockups = addressLockUps[who];
        for (uint i = 0; i < lockups.length; ++i) {
            if (!lockups[i].isClaimed) {
                if (now >= eventsStartTime[lockups[i].eventName].add(lockups[i].eventStartOffset))
                    return 0;
                uint currentLockupWaitTime = eventsStartTime[lockups[i].eventName].add(lockups[i].eventStartOffset).sub(now);
                if (shortestTime > currentLockupWaitTime)
                    shortestTime = currentLockupWaitTime;
            }
        }
        return shortestTime;
    }

    function getAddressEventIndices(address who) external view returns(uint[] memory) {
        uint[] memory indices = new uint[](eventNames.length);
        uint currentIndex = 0;
        LockUp[] memory lockups = addressLockUps[who];

        for (uint i = 0; i < lockups.length; i++) {
            for (uint j = 0; j < eventNames.length; j++)
                if (compareStrings(lockups[i].eventName, eventNames[j])) {
                    uint index = j;
                    uint k = 0;
                    while(indices[k] != index && k < currentIndex)
                        k++;
                    if (k > currentIndex || currentIndex == 0)
                        indices[currentIndex++] = index;
                }
        }

        uint[] memory temp = new uint[](currentIndex);
        for (uint i = currentIndex; i < indices.length; i++)
            temp[i] = indices[i];  

        return temp;
    }

    event EventAdded(string eventName, uint startTime);

    event EventStartTimeChanged(string eventName, uint oldStartTime, uint newStartTime);

    event LockUpClaimed(address who, string eventName, uint tokenAmount);

    function lockUpBuilder(string memory eventName, uint tokenAmount, uint eventStartOffset) internal view returns(LockUp memory) {
        require(events[eventName], "Event doesn't exist.");
        require(tokenAmount != 0, "Token amount is 0.");
        return LockUp({
            eventName: eventName,
            tokenAmount: tokenAmount,
            eventStartOffset: eventStartOffset,
            isClaimed: false
        });
    }

    function getNumberOfEvents() public view returns(uint) {
        return eventNames.length;
    }

    function compareStrings (string memory a, string memory b) internal pure returns (bool){
       return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
