// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

abstract contract MudTest is Test {
  address public worldAddress;

  function setUp() public virtual {
    worldAddress = vm.parseAddress(vm.readFile(".mudtest"));
    StoreSwitch.setStoreAddress(worldAddress);
  }
}
