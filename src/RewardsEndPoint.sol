// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@oz/security/ReentrancyGuard.sol";


interface IRewardsManager {
  function notifyTransfer(address from, address to, uint256 amount) external;
  function addReward(uint256 epochId, address vault, address token, uint256 amount) external;
  function currentEpoch() external view returns (uint256);
}

/// @author Alex The Entreprenerd for BadgerDAO
/// @notice https://miro.com/app/board/uXjVOmA0ZE4=/?share_link_id=946373148776
///   A contract to deposit your bTokens so you can still receive rewards
///   Using caller incentives to keep the flow going
contract RewardsEndPoint is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // All of the base code for any BadgerRewards Endpoint
  // Effectively a staking contract that holds funds and then sends rewards back to rewards manager allowing claims

  // RewardsManager Contract we will be claiming from
  // We'll also send the rewards to this contract so user can claim all in one place
  IRewardsManager public immutable BADGER_TREE;
  
  // Vault token that we need to claim for
  // This token will remain here 
  IERC20 public immutable VAULT; 

  uint256 internal constant MAX_BPS = 10_000;
  uint256 internal constant MAX_CALLER_INCENTIVE = 3_001; // 3001 so we can use < and save 3 gas
  uint256 public immutable CALLER_INCENTIVE;

  constructor(IRewardsManager rewardsManager, IERC20 vaultBeingForwarded, uint256 callerIncentive) {
    require(rewardsManager != address(0));
    require(callerIncentive < MAX_CALLER_INCENTIVE); // 3% pretty juicy

    BADGER_TREE = rewardsManager;
    CALLER_INCENTIVE = callerIncentive;
    VAULT = vaultBeingForwarded;
  }

  /// === Handle Rewards === ///

  /// @dev Handles the case of rewards being in this contract, 
  ///   so they can be sweeped by sending them to rewards manager for later claim
  function forward(IERC20 token) external nonReentant {
    uint256 balance = token.balanceOf(address(this));

    token.safeApprove(address(BADGER_TREE), balance);
    BADGER_TREE.addReward(BADGER_TREE.currentEpoch(), address(this), address(token), balance);

    // TODO: Calculate and send Caller Incentive
  }

  /// @dev Handles the case of claiming the rewards, and then forwarding them
  function claimAndForward() external nonReentant {
  
  }

  /// @dev 
  function doTheThing() external virtual {
    // Then does the function it needs (e.g. LP into Balancer)

    // Creates LP token, (or just a virtual position via RewardsManager, using the balance received)
    BADGER_TREE.notifyTransfer(address(0), msg.sender, 0); // TODO: Change 0 to amount


    // Those rewards will now be tracked under this contract via the rewardsManager and can be forwarded
  }

  function undoTheThing() external virtual {
    // Opposite of DoTheThing

    BADGER_TREE.notifyTransfer(msg.sender, address(0), 0); // TODO: Change 0 to amount
  }
}
