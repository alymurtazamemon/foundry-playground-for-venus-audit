// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAccessControlManager {
    function isAllowedToCall(address account, string calldata functionSig) external view returns (bool);

    function grantRole(bytes32 role, address account) external;

    function giveCallPermission(address contractAddress, string calldata functionSig, address accountToPermit) external;
}

interface IComptroller {
    function _setAccessControl(address newAccessControlAddress) external returns (uint256);

    function _setComptrollerLens(address comptrollerLens_) external returns (uint256);

    function _setPriceOracle(address newOracle) external returns (uint256);

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256);

    function allMarkets(uint256 index) external view returns (address);

    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);

    function _supportMarket(address vToken) external returns (uint256);

    function _setCollateralFactor(address vToken, uint256 newCollateralFactorMantissa) external returns (uint256);

    function _setMarketSupplyCaps(address[] calldata vTokens, uint256[] calldata newSupplyCaps) external;

    function _setMarketBorrowCaps(address[] calldata vTokens, uint256[] calldata newBorrowCaps) external;

    function _setPrimeToken(address _prime) external returns (uint);
}

interface IVBep20Harness {
    function mint(uint mintAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
}

interface BEP20Base {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);
}

interface BEP20 is BEP20Base {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IBEP20Harness is BEP20 {
    function transfer(address to, uint256 value) external returns (bool);
}

interface IXVSStore {
    function setNewOwner(address _owner) external;

    function setRewardToken(address _tokenAddress, bool status) external;
}

interface IXVSVaultScenario {
    function setXvsStore(address _xvs, address _xvsStore) external;

    function setAccessControl(address newAccessControlAddress) external;

    function add(
        address _rewardToken,
        uint256 _allocPoint,
        address _token,
        uint256 _rewardPerBlock,
        uint256 _lockPeriod
    ) external;

    function setPrimeToken(address _primeToken, address _primeRewardToken, uint256 _primePoolId) external;

    function deposit(address _rewardToken, uint256 _pid, uint256 _amount) external;
}

interface IXVS {
    function approve(address spender, uint rawAmount) external returns (bool);

    function transfer(address dst, uint rawAmount) external returns (bool);
}
