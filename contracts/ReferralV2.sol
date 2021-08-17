// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.0;
import "./ReferralOwnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ReferralV2 is ReferralOwnable, Initializable {
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
        uint256 totalCommission; // Total earned referral commission ($KAIJU)
        uint256 rewardDebt; // Pending commission to harvest ($KAIJU)        
      }
      
    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address fromuser, address referrer, uint256 commission);
    event HarvestCommission(address indexed user, uint256 commission);
    event OperatorUpdated(address indexed operator, bool indexed status);
    event CommissionRateUpdated(uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionRecorded_v2(address fromuser, uint256 commission);

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
        emit CommissionRateUpdated(referralCommissionRate, _referralCommissionRate);
        referralCommissionRate = _referralCommissionRate;        
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
            UserInfo storage _userinfo = userInfo[_user];
            address referrer = _userinfo.referrers;
            uint256 commissionAmount = _amount.mul(referralCommissionRate).div(10000);            

            if (referrer != address(0) && commissionAmount > 0) {      
                _userinfo.totalCommission = _userinfo.totalCommission.add(commissionAmount); 
                _userinfo.rewardDebt += _userinfo.rewardDebt.add(commissionAmount);                          
                emit ReferralCommissionRecorded(_user, referrer, commissionAmount);
            }
        }
    }

     function CalculateCommission_v2(address _user) public onlyOwner
    {  
        uint256 commissionAmount = 1000;
        UserInfo storage _userinfo = userInfo[_user];
        _userinfo.totalCommission = _userinfo.totalCommission.add(commissionAmount); 
        _userinfo.rewardDebt += _userinfo.rewardDebt.add(commissionAmount);          
        emit ReferralCommissionRecorded_v2(_user, commissionAmount);       
    }

    function harvestCommission(uint256 _amount) public {          
       require (_amount > 0, 'withdraw: not valid amount');          

       UserInfo storage _userinfo = userInfo[msg.sender]; 
       require(_userinfo.rewardDebt >= _amount, "withdraw: Insufficient");   
       
       uint256 tokenSupply = IERC20(monstertoken).balanceOf(address(this));
       uint256 withdrawamount;

        if (tokenSupply >= _amount)
        { withdrawamount = _amount; }       
       else { withdrawamount = tokenSupply; }

        IERC20(monstertoken).safeTransfer(msg.sender, withdrawamount);    
        userInfo[msg.sender].rewardDebt = _userinfo.rewardDebt.sub(withdrawamount);    

       emit HarvestCommission(msg.sender, _amount);       
    }

     function getReferral(address _user) external view returns(address) {        
        return  userInfo[_user].referrers;
    }

    function getPendingComm(address _user) external view returns(uint256) {        
        return  userInfo[_user].rewardDebt;
    }  

     function drainBEP20Token(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.safeTransfer(_to, _amount);
    }

}