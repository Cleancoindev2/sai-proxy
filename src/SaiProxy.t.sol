pragma solidity ^0.4.16;

import "ds-test/test.sol";
import "ds-proxy/proxy.sol";

import "sai/tub.sol";
import {SaiTestBase} from "sai/sai.t.sol";

import "./SaiProxy.sol";

contract SaiProxyExtended is SaiProxy {
    function open(address _tub) {
        var tub = SaiTub(_tub);
        tub.open();
    }
    function lock(address _tub, bytes32 cup, uint wad) {
        var tub = SaiTub(_tub);
        ERC20(tub.skr()).approve(tub, wad);
        tub.lock(cup, wad);
    }
}

contract SaiProxyTest is SaiTestBase {
    SaiProxyExtended proxy;

    function setUp() {
        super.setUp();
        proxy = new SaiProxyExtended();
        mom.setHat(1000 ether);
        gem.mint(900 ether);
    }

    function proxyDraw(bytes32 cup, uint wad, uint mat) {
        assertEq(sai.balanceOf(this), 0 ether);
        gem.transfer(proxy, 100 ether);
        if (cup != "") {
            proxy.draw(TubInterface(tub), cup, wad, ray(mat));
        } else {
            proxy.draw(TubInterface(tub), wad, ray(mat));
        }
        var (,ink,art,) = tub.cups(1);
        assertEq(sai.balanceOf(proxy), wad);
        assertEq(art, rdiv(wad, tub.chi()));
        assertEq(ink, wdiv(rmul(wmul(vox.par(), wad), ray(mat)), tub.tag()));
    }

    function proxyWipe(bytes32 cup, uint wad, uint mat) {
        var saiBalance = uint(sai.balanceOf(proxy));
        proxy.wipe(TubInterface(tub), cup, wad, ray(mat));
        var (,ink,art,) = tub.cups(1);
        assertEq(sai.balanceOf(proxy), 10 ether);
        assertEq(art, sub(saiBalance, wad));
        assertEq(ink, wmul(sub(saiBalance, wad), mat));
    }

    function testProxyDraw() {
        proxyDraw("", 50 ether, 1.5 ether);
        assertEq(skr.balanceOf(proxy), 0);
    }

    function testProxyDrawChangeMat() {
        proxyDraw("", 50 ether, 1 ether);
        assertEq(skr.balanceOf(proxy), 0);
    }

    function testProxyDrawSKRInBalance() {
        tub.join(50 ether);
        skr.transfer(proxy, 50 ether);
        assertEq(skr.balanceOf(proxy), 50 ether);
        proxyDraw("", 50 ether, 1.5 ether);
        assertEq(skr.balanceOf(proxy), 0);
    }

    function testProxyDrawSKRLocked() {
        proxy.open(tub);
        tub.join(50 ether);
        skr.transfer(proxy, 50 ether);
        proxy.lock(tub, 1, 50 ether);
        var (,ink,,) = tub.cups(1);
        assertEq(ink, 50 ether);
        proxyDraw(1, 50 ether, 1.5 ether);
        assertEq(skr.balanceOf(proxy), 0);
    }

    function testProxyDrawSKRLockedExceed() {
        proxy.open(tub);
        tub.join(100 ether);
        skr.transfer(proxy, 100 ether);
        proxy.lock(tub, 1, 100 ether);
        var (,ink,,) = tub.cups(1);
        assertEq(ink, 100 ether);
        proxyDraw(1, 50 ether, 1.5 ether);
    }

    function testFailProxyDrawBelowTubMat() {
        proxyDraw("", 50 ether, 0.9999 ether);
    }

    function testProxyDrawAfterPeriodChi() {
        mom.setTax(1000008022568992670911001251);  // 200% / day
        vox.warp(1 days);
        proxyDraw("", 100 ether, 1 ether);
        assertEq(skr.balanceOf(proxy), 0);
    }

    function testProxyDrawAfterPeriodPar() {
        mom.setWay(1000008022568992670911001251);  // 200% / day
        vox.warp(1 days);
        proxyDraw("", 50 ether, 1 ether);
        assertEq(skr.balanceOf(proxy), 0);
    }

    function testProxyWipe() {
        proxyDraw("", 50 ether, 1.5 ether);
        proxyWipe(1, 40 ether, 1.5 ether);
    }

    function testProxyChangeMat() {
        proxyDraw("", 50 ether, 1.5 ether);
        proxyWipe(1, 40 ether, 1 ether);
    }

    function testFailProxyWipeBelowTubMat() {
        proxyDraw("", 50 ether, 1.5 ether);
        proxyWipe(1, 40 ether, 0.9999 ether);
    }
}

contract SaiDSProxyTest is SaiTestBase {
    DSProxy    proxy;

    bytes code;
    bytes data;

    function setUp() public {
        super.setUp();
        DSProxyFactory factory = new DSProxyFactory();
        proxy = factory.build();

        gem.push(proxy, 100 ether);
    }

    // These tests work by calling `this.foo(args)`, to set the code and
    // data state vars with the corresponding contract code and calldata
    // (including the args), followed by `execute()` to actually make
    // the proxy call. `foo` needs to have the same call signature as
    // the actual proxy function that is being tested.
    //
    // The main reason for the `this.foo` abstraction is easy
    // construction of the correct calldata.
    function execute() logs_gas returns (address, bytes32) {
        return proxy.execute(code, data);
    }
    // n.b. `code` given below *are not optimised*. To use in a
    // frontend, compile this project with SOLC_FLAGS=--optimize and
    // copy from the corresponding files.

    // TODO: we should have some checks that the `code` here is actually
    // the same as that in the deployed contract, otherwise changes to
    // the proxy functions will be ahead of the `code`.
    function trustAll(address tub, address tap, bool wat) external {
        code = hex"6060604052341561000f57600080fd5b6107648061001e6000396000f300606060405260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806343ed0f5014610046575b600080fd5b341561005157600080fd5b6100a7600480803573ffffffffffffffffffffffffffffffffffffffff1690602001909190803573ffffffffffffffffffffffffffffffffffffffff1690602001909190803515159060200190919050506100a9565b005b6000806000808673ffffffffffffffffffffffffffffffffffffffff16637bd2bea76000604051602001526040518163ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401602060405180830381600087803b151561011b57600080fd5b6102c65a03f1151561012c57600080fd5b5050506040518051905093508673ffffffffffffffffffffffffffffffffffffffff166312d43a516000604051602001526040518163ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401602060405180830381600087803b15156101a457600080fd5b6102c65a03f115156101b557600080fd5b5050506040518051905092508673ffffffffffffffffffffffffffffffffffffffff16630f8a771e6000604051602001526040518163ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401602060405180830381600087803b151561022d57600080fd5b6102c65a03f1151561023e57600080fd5b5050506040518051905091508673ffffffffffffffffffffffffffffffffffffffff16639166cba46000604051602001526040518163ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401602060405180830381600087803b15156102b657600080fd5b6102c65a03f115156102c757600080fd5b5050506040518051905090508373ffffffffffffffffffffffffffffffffffffffff166306262f1b88876040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018215151515815260200192505050600060405180830381600087803b151561037957600080fd5b6102c65a03f1151561038a57600080fd5b5050508273ffffffffffffffffffffffffffffffffffffffff166306262f1b88876040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018215151515815260200192505050600060405180830381600087803b151561043357600080fd5b6102c65a03f1151561044457600080fd5b5050508173ffffffffffffffffffffffffffffffffffffffff166306262f1b88876040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018215151515815260200192505050600060405180830381600087803b15156104ed57600080fd5b6102c65a03f115156104fe57600080fd5b5050508073ffffffffffffffffffffffffffffffffffffffff166306262f1b88876040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018215151515815260200192505050600060405180830381600087803b15156105a757600080fd5b6102c65a03f115156105b857600080fd5b5050508173ffffffffffffffffffffffffffffffffffffffff166306262f1b87876040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018215151515815260200192505050600060405180830381600087803b151561066157600080fd5b6102c65a03f1151561067257600080fd5b5050508073ffffffffffffffffffffffffffffffffffffffff166306262f1b87876040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018215151515815260200192505050600060405180830381600087803b151561071b57600080fd5b6102c65a03f1151561072c57600080fd5b505050505050505050505600a165627a7a72305820af66cc2b9dcbe6873f27fdd6eeb37231f883f8e5f42d152fd43d2fb240c652fe0029";
        data = msg.data;
        execute();
    }
    function join(address tub, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101178061001e6000396000f300606060405263ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416633b4da69f8114603b57600080fd5b3415604557600080fd5b606773ffffffffffffffffffffffffffffffffffffffff600435166024356069565b005b8173ffffffffffffffffffffffffffffffffffffffff1663049878f3826040517c010000000000000000000000000000000000000000000000000000000063ffffffff84160281526004810191909152602401600060405180830381600087803b151560d457600080fd5b6102c65a03f1151560e457600080fd5b50505050505600a165627a7a723058209995bfaf2998a0f7cc27f42f0f6df145200d0df49c04fedd69982c4e90a1f1cd0029";
        data = msg.data;
        execute();
    }
    function exit(address tub, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101178061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663ef693bed8114603b57600080fd5b3415604557600080fd5b606773ffffffffffffffffffffffffffffffffffffffff600435166024356069565b005b8173ffffffffffffffffffffffffffffffffffffffff16637f8661a1826040517c010000000000000000000000000000000000000000000000000000000063ffffffff84160281526004810191909152602401600060405180830381600087803b151560d457600080fd5b6102c65a03f1151560e457600080fd5b50505050505600a165627a7a72305820b359d812cfce1e17d12fa26456fdb0b6e2f394186d67ef1fab6a44803c04ee560029";
        data = msg.data;
        execute();
    }
    function open(address tub) external returns (bytes32 cup) {
        code = hex"6060604052341561000f57600080fd5b6101348061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663b95460f8811461003c57600080fd5b341561004757600080fd5b61006873ffffffffffffffffffffffffffffffffffffffff6004351661007a565b60405190815260200160405180910390f35b60008173ffffffffffffffffffffffffffffffffffffffff1663fcfff16f6000604051602001526040518163ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401602060405180830381600087803b15156100e857600080fd5b6102c65a03f115156100f957600080fd5b505050604051805193925050505600a165627a7a723058202afe78a3f424cd1930c7d9af6ece33f87ed742019ba2948d8141ca8d877473980029";
        data = msg.data;
        (,cup) = execute();
    }
    function give(address tub, bytes32 cup, address lad) external {
        code = hex"6060604052341561000f57600080fd5b6101418061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663da93dfcf811461003c57600080fd5b341561004757600080fd5b61007273ffffffffffffffffffffffffffffffffffffffff6004358116906024359060443516610074565b005b8273ffffffffffffffffffffffffffffffffffffffff1663baa8529c83836040517c010000000000000000000000000000000000000000000000000000000063ffffffff8516028152600481019290925273ffffffffffffffffffffffffffffffffffffffff166024820152604401600060405180830381600087803b15156100fc57600080fd5b6102c65a03f1151561010d57600080fd5b5050505050505600a165627a7a72305820bcd361a1f9c0a17b6eed07900ae869031127555ec6656c422ea7f7714960fda80029";
        data = msg.data;
        execute();
    }
    function lock(address tub, bytes32 cup, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101218061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663a80de0e88114603b57600080fd5b3415604557600080fd5b606a73ffffffffffffffffffffffffffffffffffffffff60043516602435604435606c565b005b8273ffffffffffffffffffffffffffffffffffffffff1663b3b77a5183836040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815260048101929092526024820152604401600060405180830381600087803b151560dd57600080fd5b6102c65a03f1151560ed57600080fd5b5050505050505600a165627a7a723058207e31992fc69491822a4655ce5de06cab8042209f2b062a970f92503bf2ac1c270029";
        data = msg.data;
        execute();
    }
    function free(address tub, bytes32 cup, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101218061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663f9ef04be8114603b57600080fd5b3415604557600080fd5b606a73ffffffffffffffffffffffffffffffffffffffff60043516602435604435606c565b005b8273ffffffffffffffffffffffffffffffffffffffff1663a5cd184e83836040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815260048101929092526024820152604401600060405180830381600087803b151560dd57600080fd5b6102c65a03f1151560ed57600080fd5b5050505050505600a165627a7a7230582011cb044f1eaeed1c69f705389051bd09d46dece31e494f70cbd6dbc9ed7780030029";
        data = msg.data;
        execute();
    }
    function draw(address tub, bytes32 cup, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101218061001e6000396000f300606060405263ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416630344a36f8114603b57600080fd5b3415604557600080fd5b606a73ffffffffffffffffffffffffffffffffffffffff60043516602435604435606c565b005b8273ffffffffffffffffffffffffffffffffffffffff1663440f19ba83836040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815260048101929092526024820152604401600060405180830381600087803b151560dd57600080fd5b6102c65a03f1151560ed57600080fd5b5050505050505600a165627a7a723058203b9b54c830c4a95702a40fa910f4b28e899dba803906fb62736ac40ab27a9c3a0029";
        data = msg.data;
        execute();
    }
    function wipe(address tub, bytes32 cup, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101218061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663a3dc65a78114603b57600080fd5b3415604557600080fd5b606a73ffffffffffffffffffffffffffffffffffffffff60043516602435604435606c565b005b8273ffffffffffffffffffffffffffffffffffffffff166373b3810183836040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815260048101929092526024820152604401600060405180830381600087803b151560dd57600080fd5b6102c65a03f1151560ed57600080fd5b5050505050505600a165627a7a72305820bd148f73b42229bb6fc1f564b7992c1e78e04f0ebcba3eec7dc9febfca41fd7d0029";
        data = msg.data;
        execute();
    }
    function shut(address tub, bytes32 cup) external {
        code = hex"6060604052341561000f57600080fd5b6101178061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663bc244c118114603b57600080fd5b3415604557600080fd5b606773ffffffffffffffffffffffffffffffffffffffff600435166024356069565b005b8173ffffffffffffffffffffffffffffffffffffffff1663b84d2106826040517c010000000000000000000000000000000000000000000000000000000063ffffffff84160281526004810191909152602401600060405180830381600087803b151560d457600080fd5b6102c65a03f1151560e457600080fd5b50505050505600a165627a7a72305820c1049b5b0713f6ec68e519ad9d83512e9f89c797d1840312afd2dbedefaa31900029";
        data = msg.data;
        execute();
    }
    function bite(address tub, bytes32 cup) external {
        code = hex"6060604052341561000f57600080fd5b6101468061001e6000396000f300606060405260043610610041576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806337cae1e414610046575b600080fd5b341561005157600080fd5b61008a600480803573ffffffffffffffffffffffffffffffffffffffff169060200190919080356000191690602001909190505061008c565b005b8173ffffffffffffffffffffffffffffffffffffffff166340cc8854826040518263ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808260001916600019168152602001915050600060405180830381600087803b151561010257600080fd5b6102c65a03f1151561011357600080fd5b50505050505600a165627a7a72305820c2140486cfdfe2bb4628eff4e021c21baddc1b1e2aca185f68e590a7abc634180029";
        data = msg.data;
        execute();
    }
    function bust(address tap, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101178061001e6000396000f300606060405263ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416631234d3078114603b57600080fd5b3415604557600080fd5b606773ffffffffffffffffffffffffffffffffffffffff600435166024356069565b005b8173ffffffffffffffffffffffffffffffffffffffff1663af378ce5826040517c010000000000000000000000000000000000000000000000000000000063ffffffff84160281526004810191909152602401600060405180830381600087803b151560d457600080fd5b6102c65a03f1151560e457600080fd5b50505050505600a165627a7a7230582091ec02c5010894d09b84e84564191fa794b94a9119efe238edc7a8751fc92f9c0029";
        data = msg.data;
        execute();
    }
    function boom(address tap, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101178061001e6000396000f300606060405263ffffffff7c010000000000000000000000000000000000000000000000000000000060003504166395c144b68114603b57600080fd5b3415604557600080fd5b606773ffffffffffffffffffffffffffffffffffffffff600435166024356069565b005b8173ffffffffffffffffffffffffffffffffffffffff1663b443a085826040517c010000000000000000000000000000000000000000000000000000000063ffffffff84160281526004810191909152602401600060405180830381600087803b151560d457600080fd5b6102c65a03f1151560e457600080fd5b50505050505600a165627a7a72305820a065acbef04a8f4b35ea22abcc871afb1c665455bfb52e2de7c0dad31fc464df0029";
        data = msg.data;
        execute();
    }
    function cash(address tap) external {
        code = hex"6060604052341561000f57600080fd5b61010a8061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663b6dc16f68114603b57600080fd5b3415604557600080fd5b606473ffffffffffffffffffffffffffffffffffffffff600435166066565b005b8073ffffffffffffffffffffffffffffffffffffffff1663961be3916040518163ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401600060405180830381600087803b151560c857600080fd5b6102c65a03f1151560d857600080fd5b505050505600a165627a7a72305820b001672337082c666c74d464e8a766e39282e34ca71cee2b2b2fcf92dc5d86250029";
        data = msg.data;
        execute();
    }
    function saisaisai(address tub, uint jam, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6103ad8061001e6000396000f300606060405263ffffffff60e060020a600035041663a93bcc58811461002357600080fd5b341561002e57600080fd5b610048600160a060020a036004351660243560443561005a565b60405190815260200160405180910390f35b600083818080600160a060020a038416637bd2bea782604051602001526040518163ffffffff1660e060020a028152600401602060405180830381600087803b15156100a557600080fd5b6102c65a03f115156100b657600080fd5b5050506040518051935050600160a060020a038416630f8a771e6000604051602001526040518163ffffffff1660e060020a028152600401602060405180830381600087803b151561010757600080fd5b6102c65a03f1151561011857600080fd5b5050506040518051925050600160a060020a0383166306262f1b85600160405160e060020a63ffffffff8516028152600160a060020a03909216600483015215156024820152604401600060405180830381600087803b151561017a57600080fd5b6102c65a03f1151561018b57600080fd5b50505081600160a060020a03166306262f1b85600160405160e060020a63ffffffff8516028152600160a060020a03909216600483015215156024820152604401600060405180830381600087803b15156101e557600080fd5b6102c65a03f115156101f657600080fd5b50505083600160a060020a031663049878f38860405160e060020a63ffffffff84160281526004810191909152602401600060405180830381600087803b151561023f57600080fd5b6102c65a03f1151561025057600080fd5b50505083600160a060020a031663fcfff16f6000604051602001526040518163ffffffff1660e060020a028152600401602060405180830381600087803b151561029957600080fd5b6102c65a03f115156102aa57600080fd5b5050506040518051915050600160a060020a03841663b3b77a51828960405160e060020a63ffffffff851602815260048101929092526024820152604401600060405180830381600087803b151561030157600080fd5b6102c65a03f1151561031257600080fd5b50505083600160a060020a031663440f19ba828860405160e060020a63ffffffff851602815260048101929092526024820152604401600060405180830381600087803b151561036157600080fd5b6102c65a03f1151561037257600080fd5b509199985050505050505050505600a165627a7a7230582059cf0749032c38be276fe082f7c71e9c59f0ac8eda9b8f446fd71f6558f7a8bb0029";
        data = msg.data;
        execute();
    }
    function approve(address tub, address guy, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b61013f8061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663e1f21c67811461003c57600080fd5b341561004757600080fd5b61007173ffffffffffffffffffffffffffffffffffffffff60043581169060243516604435610073565b005b8273ffffffffffffffffffffffffffffffffffffffff1663095ea7b383836040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815273ffffffffffffffffffffffffffffffffffffffff90921660048301526024820152604401600060405180830381600087803b15156100fa57600080fd5b6102c65a03f1151561010b57600080fd5b5050505050505600a165627a7a7230582031efbc0dac4018e79510f8e22b1bf46e9eba6c578632c3f61d2058f3cc4a801c0029";
        data = msg.data;
        execute();
    }
    function trust(address tub, address guy, bool wat) external {
        code = hex"6060604052341561000f57600080fd5b6101438061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663aaaf8ab2811461003c57600080fd5b341561004757600080fd5b61007373ffffffffffffffffffffffffffffffffffffffff600435811690602435166044351515610075565b005b8273ffffffffffffffffffffffffffffffffffffffff166306262f1b83836040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815273ffffffffffffffffffffffffffffffffffffffff909216600483015215156024820152604401600060405180830381600087803b15156100fe57600080fd5b6102c65a03f1151561010f57600080fd5b5050505050505600a165627a7a7230582023c35c45d22a811605d4630d26373e6ffed94893f25ff66fc32c1ba4608c7d5f0029";
        data = msg.data;
        execute();
    }
    function transfer(address token, address guy, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b61014f8061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663beabacc8811461003c57600080fd5b341561004757600080fd5b61007173ffffffffffffffffffffffffffffffffffffffff60043581169060243516604435610073565b005b8273ffffffffffffffffffffffffffffffffffffffff1663a9059cbb83836000604051602001526040517c010000000000000000000000000000000000000000000000000000000063ffffffff851602815273ffffffffffffffffffffffffffffffffffffffff90921660048301526024820152604401602060405180830381600087803b151561010357600080fd5b6102c65a03f1151561011457600080fd5b505050604051805150505050505600a165627a7a723058200f432a25a3619b35d26e315b33c4d2f1e84bcb1afd838b298fdc2f0f3e0e16770029";
        data = msg.data;
        execute();
    }
    function deposit(address token, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b60f98061001d6000396000f300606060405263ffffffff60e060020a60003504166347e7ef248114602257600080fd5b604473ffffffffffffffffffffffffffffffffffffffff600435166024356046565b005b8173ffffffffffffffffffffffffffffffffffffffff16816040517f6465706f736974282900000000000000000000000000000000000000000000008152600901604051809103902060e060020a9004906040518263ffffffff1660e060020a02815260040160006040518083038185886187965a03f19350505050151560c957fe5b50505600a165627a7a723058208b46775ab20436dd1b40d2bfa4712754e913e49a73973f8f99970f2850ade7650029";
        data = msg.data;
        execute();
    }
    function withdraw(address token, uint wad) external {
        code = hex"6060604052341561000f57600080fd5b6101178061001e6000396000f300606060405263ffffffff7c0100000000000000000000000000000000000000000000000000000000600035041663f3fef3a38114603b57600080fd5b3415604557600080fd5b606773ffffffffffffffffffffffffffffffffffffffff600435166024356069565b005b8173ffffffffffffffffffffffffffffffffffffffff16632e1a7d4d826040517c010000000000000000000000000000000000000000000000000000000063ffffffff84160281526004810191909152602401600060405180830381600087803b151560d457600080fd5b6102c65a03f1151560e457600080fd5b50505050505600a165627a7a723058205526bb9fea8b2fd0497993b31439b25f9843c1f46a8de6f6837555ed8ecb87040029";
        data = msg.data;
        execute();
    }
    function testProxyTrust() public {
        assertTrue(!gem.trusted(proxy, tub));
        this.trust(gem, tub, true);
        assertTrue(gem.trusted(proxy, tub));
    }
    function testProxyApprove() public {
        assertEq(gem.allowance(proxy, tub), 0);
        this.approve(gem, tub, 10);
        assertEq(gem.allowance(proxy, tub), 10);
    }
    function testProxyTransfer() public {
        assertEq(gem.balanceOf(address(0x1)), 0);
        this.transfer(gem, address(0x1), 1 ether);
        assertEq(gem.balanceOf(address(0x1)), 1 ether);
    }
    // TODO: missing test for deposit & withdraw
    function testProxyTrustAll() public {
        assertTrue(!gem.trusted(proxy, tub));
        assertTrue(!gov.trusted(proxy, tub));
        assertTrue(!skr.trusted(proxy, tub));
        assertTrue(!sai.trusted(proxy, tub));

        assertTrue(!skr.trusted(proxy, tap));
        assertTrue(!sai.trusted(proxy, tap));

        this.trustAll(tub, tap, true);

        assertTrue(gem.trusted(proxy, tub));
        assertTrue(gov.trusted(proxy, tub));
        assertTrue(skr.trusted(proxy, tub));
        assertTrue(sai.trusted(proxy, tub));

        assertTrue(skr.trusted(proxy, tap));
        assertTrue(sai.trusted(proxy, tap));

        this.trustAll(tub, tap, false);

        assertTrue(!gem.trusted(proxy, tub));
        assertTrue(!gov.trusted(proxy, tub));
        assertTrue(!skr.trusted(proxy, tub));
        assertTrue(!sai.trusted(proxy, tub));

        assertTrue(!skr.trusted(proxy, tap));
        assertTrue(!sai.trusted(proxy, tap));
    }
    function testProxyJoin() public {
        this.trustAll(tub, tap, true);

        assertEq(skr.balanceOf(proxy),  0 ether);

        this.join(tub, 50 ether);

        assertEq(skr.balanceOf(proxy), 50 ether);
    }
    function testProxyExit() public {
        this.trustAll(tub, tap, true);
        this.join(tub, 50 ether);

        assertEq(skr.balanceOf(proxy), 50 ether);
        assertEq(gem.balanceOf(proxy), 50 ether);

        this.exit(tub, 10 ether);

        assertEq(skr.balanceOf(proxy), 40 ether);
        assertEq(gem.balanceOf(proxy), 60 ether);
    }
    function testProxyOpen() public {
        var cup1 = this.open(tub);
        assertEq(cup1, bytes32(1));

        assertEq(tub.lad(cup1), proxy);
        assertEq(tub.ink(cup1), 0);
        assertEq(tub.tab(cup1), 0);

        var cup2 = this.open(tub);
        assertEq(cup2, bytes32(2));
    }
    function testProxyGive() public {
        var cup = this.open(tub);

        assertEq(tub.lad(cup), proxy);
        this.give(tub, cup, this);
        assertEq(tub.lad(cup), this);
    }
    function testProxyLock() public {
        this.trustAll(tub, tap, true);
        var cup = this.open(tub);
        this.join(tub, 50 ether);

        assertEq(skr.balanceOf(proxy), 50 ether);
        assertEq(tub.ink(cup), 0);
        this.lock(tub, cup, 50 ether);
        assertEq(skr.balanceOf(proxy),  0 ether);
        assertEq(tub.ink(cup), 50 ether);
    }
    function testProxyFree() public {
        this.trustAll(tub, tap, true);
        var cup = this.open(tub);
        this.join(tub, 50 ether);
        this.lock(tub, cup, 50 ether);

        assertEq(skr.balanceOf(proxy), 0 ether);
        assertEq(tub.ink(cup), 50 ether);
        this.free(tub, cup, 20 ether);
        assertEq(skr.balanceOf(proxy), 20 ether);
        assertEq(tub.ink(cup), 30 ether);
    }
    function testProxyDraw() public {
        this.trustAll(tub, tap, true);
        var cup = this.open(tub);
        this.join(tub, 50 ether);
        this.lock(tub, cup, 50 ether);

        assertEq(sai.balanceOf(proxy),  0 ether);
        assertEq(tub.tab(cup),  0 ether);
        this.draw(tub, cup, 10 ether);
        assertEq(sai.balanceOf(proxy), 10 ether);
        assertEq(tub.tab(cup), 10 ether);
    }
    function testProxyWipe() public {
        this.trustAll(tub, tap, true);
        var cup = this.open(tub);
        this.join(tub, 50 ether);
        this.lock(tub, cup, 50 ether);
        this.draw(tub, cup, 10 ether);

        assertEq(sai.balanceOf(proxy), 10 ether);
        assertEq(tub.tab(cup), 10 ether);
        this.wipe(tub, cup, 3 ether);
        assertEq(sai.balanceOf(proxy),  7 ether);
        assertEq(tub.tab(cup), 7 ether);
    }
    function testProxyShut() public {
        this.trustAll(tub, tap, true);
        var cup = this.open(tub);
        this.join(tub, 50 ether);
        this.lock(tub, cup, 50 ether);
        this.draw(tub, cup, 10 ether);

        assertEq(tub.ink(cup), 50 ether);
        assertEq(tub.tab(cup), 10 ether);
        this.shut(tub, cup);
        assertEq(tub.ink(cup),  0 ether);
        assertEq(tub.tab(cup),  0 ether);
    }
    function testProxyBust() public {
        this.trustAll(tub, tap, true);
        mom.setHat(100 ether);
        mom.setMat(ray(wdiv(3 ether, 2 ether)));  // 150% liq limit
        mark(2 ether);

        this.join(tub, 10 ether);
        var cup = this.open(tub);
        this.lock(tub, cup, 10 ether);

        mark(3 ether);
        this.draw(tub, cup, 16 ether);  // 125% collat
        mark(2 ether);

        assertTrue(!tub.safe(cup));
        tub.bite(cup);

        // get 2 skr, pay 4 sai (25% of the debt)
        var sai_before = sai.balanceOf(proxy);
        var skr_before = skr.balanceOf(proxy);
        assertEq(sai_before, 16 ether);
        this.bust(tap, 2 ether);
        var sai_after = sai.balanceOf(proxy);
        var skr_after = skr.balanceOf(proxy);
        assertEq(sai_before - sai_after, 4 ether);
        assertEq(skr_after - skr_before, 2 ether);
    }
    function testProxyBoom() public {
        this.trustAll(tub, tap, true);
        sai.mint(tap, 50 ether);
        this.join(tub, 60 ether);

        assertEq(sai.balanceOf(proxy),  0 ether);
        assertEq(skr.balanceOf(proxy), 60 ether);
        this.boom(tap, 50 ether);
        assertEq(sai.balanceOf(proxy), 50 ether);
        assertEq(skr.balanceOf(proxy), 10 ether);
        assertEq(tap.joy(), 0);
    }
    function testProxyCash() public {
        this.trustAll(tub, tap, true);
        mom.setHat(5 ether);            // 5 sai debt ceiling
        tag.poke(bytes32(1 ether));   // price 1:1 gem:ref
        mom.setMat(ray(2 ether));       // require 200% collat
        this.join(tub, 10 ether);
        var cup = this.open(tub);
        this.lock(tub, cup, 10 ether);
        this.draw(tub, cup, 5 ether);
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(sai.balanceOf(proxy),  5 ether);
        assertEq(skr.balanceOf(proxy),  0 ether);
        assertEq(gem.balanceOf(proxy), 90 ether);
        this.cash(tap);
        assertEq(sai.balanceOf(proxy),   0 ether);
        assertEq(skr.balanceOf(proxy),   0 ether);
    }
    function testProxySaiSaiSai() public {
        // put in 10 ether, get 10 skr, lock it all and draw 5 sai
        this.saisaisai(tub, 10 ether, 5 ether);
        assertEq(sai.balanceOf(proxy), 5 ether);
    }
}
