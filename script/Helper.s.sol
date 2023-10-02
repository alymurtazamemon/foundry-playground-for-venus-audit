// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// * forge
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// * interface
import "test/Interfaces.sol";

// * contracts
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {PrimeLiquidityProvider} from "../src/contracts/Tokens/Prime/PrimeLiquidityProvider.sol";
import {Prime} from "../src/contracts/Tokens/Prime/Prime.sol";
import {PrimeScenario} from "../src/contracts/test/PrimeScenario.sol";
import {MockProtocolShareReserve} from "../src/contracts/test/MockProtocolShareReserve.sol";

// * venus
import "@venusprotocol/oracle/contracts/ResilientOracle.sol";
import "@venusprotocol/governance-contracts/contracts/Governance/AccessControlManager.sol";

contract HelperConfig is Script {
    // * users
    address immutable wallet;
    address constant user1 = address(2);
    address constant user2 = address(3);
    address constant user3 = address(4);

    // * instances
    FakeOracle oracle;
    MockProtocolShareReserve protocolShareReserve;
    IAccessControlManager accessControl;
    IComptroller comptroller;
    address comptrollerLens;
    IBEP20Harness usdt;
    IBEP20Harness eth;
    IBEP20Harness wbnb;
    address interestRateModelHarness;
    IVBep20Harness vusdt;
    IVBep20Harness veth;
    IVBep20Harness vbnb;
    IXVS xvs;
    IXVSStore xvsStore;
    IXVSVaultScenario xvsVault;
    PrimeLiquidityProvider primeLiquidityProvider;
    PrimeScenario prime;

    // * constants
    uint256 constant bigNumber18 = 1000000000000000000;
    uint256 constant bigNumber16 = 10000000000000000;

    constructor() {
        bytes memory args;
        wallet = address(this);

        // oracle = getContractAddress(
        //     "ResilientOracle.sol:ResilientOracle",
        //     bytes("")
        // );

        accessControl = IAccessControlManager(
            getContractAddress("AccessControlManager.sol:AccessControlManager", bytes(""))
        );

        // * comptroller
        comptroller = IComptroller(getContractAddress("ComptrollerMock.sol:ComptrollerMock", bytes("")));
        comptrollerLens = getContractAddress("ComptrollerLens.sol:ComptrollerLens", bytes(""));

        // * grant permissions
        accessControl.giveCallPermission(address(0), "_setLiquidationIncentive(uint256)", address(this));
        accessControl.giveCallPermission(address(0), "_supportMarket(address)", address(this));
        accessControl.giveCallPermission(address(0), "_setCollateralFactor(address,uint256)", address(this));
        accessControl.giveCallPermission(address(0), "_setMarketSupplyCaps(address[],uint256[])", address(this));
        accessControl.giveCallPermission(address(0), "_setMarketBorrowCaps(address[],uint256[])", address(this));
        accessControl.giveCallPermission(address(0), "add(address,uint256,address,uint256,uint256)", address(this));
        accessControl.giveCallPermission(address(0), "setLimit(uint256,uint256)", address(this));
        accessControl.giveCallPermission(address(0), "addMarket(address,uint256,uint256)", address(this));
        accessControl.giveCallPermission(address(0), "togglePause()", address(this));

        // * setters
        comptroller._setAccessControl(address(accessControl));
        comptroller._setComptrollerLens(comptrollerLens);
        // comptroller._setPriceOracle(oracle);
        comptroller._setLiquidationIncentive(1 * 10 ** 18);

        // * usdt
        usdt = IBEP20Harness(getBep20Harness("usdt", "BEP20 usdt"));

        // * eth
        eth = IBEP20Harness(getBep20Harness("eth", "BEP20 eth"));

        // * wbnb
        wbnb = IBEP20Harness(getBep20Harness("wbnb", "BEP20 wbnb"));

        // * interest rate model harness
        args = abi.encode(18 * 5);
        interestRateModelHarness = getContractAddress("InterestRateModelHarness.sol:InterestRateModelHarness", args);

        // * vusdt
        vusdt = IVBep20Harness(getVBep20Harness(address(usdt), "VToken usdt", "vusdt"));

        // * veth
        veth = IVBep20Harness(getVBep20Harness(address(eth), "VToken eth", "veth"));

        // * vbnb
        vbnb = IVBep20Harness(getVBep20Harness(address(wbnb), "VToken bnb", "vbnb"));

        args = abi.encode(address(comptroller), address(wbnb), address(vbnb));
        protocolShareReserve = MockProtocolShareReserve(
            getContractAddress("MockProtocolShareReserve.sol:MockProtocolShareReserve", args)
        );

        assert(protocolShareReserve.MAX_PERCENT() == 100);

        // 0.2 reserve factor
        veth._setReserveFactor(bigNumber16 * 20); // 1e16 * 20
        vusdt._setReserveFactor(bigNumber16 * 20); // 1e16 * 20

        // oracle.getUnderlyingPrice.returns((vToken: string) => {
        //     if (vToken == vusdt.address) {
        //     return convertToUnit(1, 18);
        //     } else if (vToken == veth.address) {
        //     return convertToUnit(1200, 18);
        //     }
        // });

        // oracle.getPrice.returns((token: string) => {
        //     if (token == xvs.address) {
        //     return convertToUnit(3, 18);
        //     }
        // });

        uint256 half = 500000000000000000; // 0.5e18
        comptroller._supportMarket(address(vusdt));
        // comptroller._setCollateralFactor(address(vusdt), half);
        comptroller._supportMarket(address(veth));
        // comptroller._setCollateralFactor(address(veth), half);

        eth.transfer(user1, bigNumber18 * 100); // 1e18 * 100
        usdt.transfer(user2, bigNumber18 * 10000); // 1e18 * 10000

        uint256[] memory supplyAndBorrowCaps = new uint256[](2);
        supplyAndBorrowCaps[0] = bigNumber18 * 10000;
        supplyAndBorrowCaps[1] = bigNumber18 * 100;

        address[] memory vTokens = new address[](2);
        vTokens[0] = address(vusdt);
        vTokens[1] = address(veth);

        comptroller._setMarketSupplyCaps(vTokens, supplyAndBorrowCaps);
        comptroller._setMarketBorrowCaps(vTokens, supplyAndBorrowCaps);

        // * XVS
        args = abi.encode(wallet);
        xvs = IXVS(getContractAddress("XVS.sol:XVS", args));

        // * oracle
        oracle = new FakeOracle(address(vusdt), address(veth), address(xvs));
        comptroller._setPriceOracle(address(oracle));
        assert(oracle.getUnderlyingPrice(address(vusdt)) == 1e18);
        assert(oracle.getUnderlyingPrice(address(veth)) == 1200e18);
        assert(oracle.getPrice(address(xvs)) == 3e18);
        comptroller._setCollateralFactor(address(vusdt), half);
        comptroller._setCollateralFactor(address(veth), half);

        // * XVSStore
        xvsStore = IXVSStore(getContractAddress("XVSStore.sol:XVSStore", bytes("")));

        // * XVSVaultScenario
        xvsVault = IXVSVaultScenario(getContractAddress("XVSVaultScenario.sol:XVSVaultScenario", bytes("")));

        xvsStore.setNewOwner(address(xvsVault));
        xvsVault.setXvsStore(address(xvs), address(xvsStore));
        xvsVault.setAccessControl(address(accessControl));

        xvs.transfer(address(xvsStore), bigNumber18 * 1000); // 1e18 * 1000
        xvs.transfer(user1, bigNumber18 * 1000000); // 1e18 * 1000000
        xvs.transfer(user2, bigNumber18 * 1000000); // 1e18 * 1000000
        xvs.transfer(user3, bigNumber18 * 1000000); // 1e18 * 1000000

        xvsStore.setRewardToken(address(xvs), true);

        uint256 lockPeriod = 300;
        uint256 allocPoint = 100;
        uint256 poolId = 0;
        uint256 rewardPerBlock = bigNumber18 * 1; // 1e18 * 1
        xvsVault.add(address(xvs), allocPoint, address(xvs), rewardPerBlock, lockPeriod);

        // * PrimeLiquidityProvider
        ERC1967Proxy proxy = new ERC1967Proxy(address(new PrimeLiquidityProvider()), bytes(""));

        address[] memory _tokens = new address[](3);
        _tokens[0] = address(xvs);
        _tokens[1] = address(usdt);
        _tokens[2] = address(eth);

        uint256[] memory _distributionSpeeds = new uint256[](3);
        _distributionSpeeds[0] = 10;
        _distributionSpeeds[1] = 10;
        _distributionSpeeds[2] = 10;

        primeLiquidityProvider = PrimeLiquidityProvider(address(proxy));
        primeLiquidityProvider.initialize(address(accessControl), _tokens, _distributionSpeeds);

        // * PrimeScenario

        proxy = new ERC1967Proxy(address(new PrimeScenario(address(wbnb), address(vbnb), 10512000)), bytes(""));
        prime = PrimeScenario(address(proxy));
        prime.initialize(
            address(xvsVault),
            address(xvs),
            0,
            1,
            2,
            address(accessControl),
            address(protocolShareReserve),
            address(primeLiquidityProvider),
            address(comptroller),
            address(oracle),
            10
        );

        xvsVault.setPrimeToken(address(prime), address(xvs), poolId);
        prime.setLimit(1000, 1000);
        prime.addMarket(
            address(vusdt),
            bigNumber18 * 1, // 1e18 * 1
            bigNumber18 * 1 // 1e18 * 1
        );
        prime.addMarket(
            address(veth),
            bigNumber18 * 1, // 1e18 * 1
            bigNumber18 * 1 // 1e18 * 1
        );
        comptroller._setPrimeToken(address(prime));
        prime.togglePause();
    }

    function getBep20Harness(string memory _tokenSymbol, string memory _tokenName) internal returns (address) {
        bytes memory args = abi.encode(
            bigNumber18 * 100000000, // 1e18 * 1e10,
            _tokenSymbol,
            18,
            _tokenName
        );
        return getContractAddress("BEP20.sol:BEP20Harness", args);
    }

    function getVBep20Harness(
        address underlying_,
        string memory name_,
        string memory symbol_
    ) internal returns (address) {
        bytes memory args = abi.encode(
            underlying_,
            comptroller,
            interestRateModelHarness,
            bigNumber18, // 1e18
            name_,
            symbol_,
            18,
            wallet
        );

        return getContractAddress("VBep20Harness.sol:VBep20Harness", args);
    }

    function getContractAddress(string memory artifactPath, bytes memory args) internal returns (address) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(artifactPath), args);

        address _address;
        assembly {
            _address := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        // console.log(_address);
        return _address;
    }
}

contract FakeOracle {
    address vusdt;
    address veth;
    address xvs;

    error vToken_Undefined(address vToken);
    error asset_Undefined(address vToken);

    constructor(address _vusdt, address _veth, address _xvs) {
        vusdt = _vusdt;
        veth = _veth;
        xvs = _xvs;
    }

    function getUnderlyingPrice(address vToken) external view returns (uint256) {
        if (vToken == vusdt) {
            return 1 * 10 ** 18;
        } else if (vToken == veth) {
            return 1200 * 10 ** 18;
        } else {
            revert vToken_Undefined(vToken);
        }
    }

    function getPrice(address asset) external view returns (uint256) {
        if (asset == xvs) {
            return 3 * 10 ** 18;
        } else {
            revert asset_Undefined(asset);
        }
    }
}
