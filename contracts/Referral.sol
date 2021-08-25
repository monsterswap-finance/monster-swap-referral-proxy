// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.0;
import "./ReferralOwnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Referral is ReferralOwnable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
     IERC20 public monstertoken;

    // Referral commission rate in basis points.
    uint16 public referralCommissionRate;

     mapping(address => bool) public operators;
     mapping(address => UserInfo) public userInfo;
     struct UserInfo {
        address referrers;     // Referrer address
        uint256 referralsCount; // Total referral downline count
        uint256 totalCommission; // Total earned referral commission (MONSTER)
        uint256 rewardDebt; // Pending commission to harvest (MOSNTER)        
      }
      
    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address fromuser, address referrer, uint256 commission);
    event HarvestCommission(address indexed user, uint256 commission);
    event OperatorUpdated(address indexed operator, bool indexed status);
    event CommissionRateUpdated(uint256 previousAmount, uint256 newAmount);

    // Max Referreal Commission : 5%
    uint16 public constant MAXIMUM_REFERRAL_COMMISSIOn = 500;

    function initialize(IERC20 _monstertoken) public initializer
    {
        monstertoken = _monstertoken;
        referralCommissionRate = 100;
    }

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    // Change Commission Rate
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOperator {
        require(_referralCommissionRate >= 0, "setReferralCommissionRate: invalid referral commission rate basis points");
        require(_referralCommissionRate < MAXIMUM_REFERRAL_COMMISSIOn, "setReferralCommissionRate: Exceed Maximum commission rate.");        
        referralCommissionRate = _referralCommissionRate;        
        emit CommissionRateUpdated(referralCommissionRate, _referralCommissionRate);
    }

    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    function recordReferral(address _user, address _referrer) public onlyOperator {
        UserInfo storage _userinfo = userInfo[_user];
         if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && _userinfo.referrers == address(0)
        ) {                    
            _userinfo.referrers = _referrer;
            _userinfo.referralsCount += 1;            
            emit ReferralRecorded(_user, _referrer);
        }
    }
    
    function CalculateCommission(address _user, uint256 _amount) public onlyOwner
    {  
        if (_amount > 0) {
            
            address referrer = userInfo[_user].referrers;
            UserInfo storage _referralInfo = userInfo[referrer];
            address referrer = userInfo[ReferralAddr].referrers;            
            uint256 commissionAmount = _amount.mul(referralCommissionRate).div(10000);            
            if (referrer != address(0) && commissionAmount > 0) {      
                _referralInfo.totalCommission = _referralInfo.totalCommission.add(commissionAmount); 
                _referralInfo.rewardDebt = _referralInfo.rewardDebt.add(commissionAmount);                          
                emit ReferralCommissionRecorded(_user, referrer, commissionAmount);
            }
        }
    }

    function harvestCommission() public 
    {                
        UserInfo storage _userinfo = userInfo[msg.sender];      
        uint256 harvestAmount = _userinfo.rewardDebt;                        
        userInfo[msg.sender].rewardDebt = 0;
        safeMonsterTransfer(address(msg.sender), harvestAmount);
        emit HarvestCommission(msg.sender, harvestAmount);       
    }

    function safeMonsterTransfer(address _to, uint256 _amount) internal {
        uint256 MonsterBal = monstertoken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > MonsterBal) {
            transferSuccess = monstertoken.transfer(_to, MonsterBal);
        } else {
            transferSuccess = monstertoken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeMonsterTransfer: Transfer failed");
    }

   function getReferralInfo(address _user) public view returns(address referrers, uint256 referralsCount, uint256 totalCommission, uint256 rewardDebt) {
        return (
            address(userInfo[_user].referrers),
            userInfo[_user].referralsCount,
            userInfo[_user].totalCommission,
            userInfo[_user].rewardDebt);
    }

    function drainBEP20Token(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.safeTransfer(_to, _amount);
    }

}