// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IStoreHook, STORE_HOOK_INTERFACE_ID } from "./IStoreHook.sol";
import { ERC165_INTERFACE_ID } from "./IERC165.sol";
import { PackedCounter } from "./PackedCounter.sol";
import { FieldLayout } from "./FieldLayout.sol";

abstract contract StoreHook is IStoreHook {
  // ERC-165 supportsInterface (see https://eips.ethereum.org/EIPS/eip-165)
  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return interfaceId == STORE_HOOK_INTERFACE_ID || interfaceId == ERC165_INTERFACE_ID;
  }

  function onBeforeSetRecord(
    bytes32,
    bytes32[] memory,
    bytes memory,
    PackedCounter,
    bytes memory,
    FieldLayout
  ) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onAfterSetRecord(
    bytes32,
    bytes32[] memory,
    bytes memory,
    PackedCounter,
    bytes memory,
    FieldLayout
  ) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onBeforeSpliceStaticData(bytes32, bytes32[] memory, uint48, uint40, bytes memory) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onAfterSpliceStaticData(bytes32, bytes32[] memory, uint48, uint40, bytes memory) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onBeforeSpliceDynamicData(
    bytes32,
    bytes32[] memory,
    uint8,
    uint40,
    uint40,
    bytes memory,
    PackedCounter
  ) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onAfterSpliceDynamicData(
    bytes32,
    bytes32[] memory,
    uint8,
    uint40,
    uint40,
    bytes memory,
    PackedCounter
  ) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onBeforeDeleteRecord(bytes32, bytes32[] memory, FieldLayout) public virtual {
    revert StoreHook_NotImplemented();
  }

  function onAfterDeleteRecord(bytes32, bytes32[] memory, FieldLayout) public virtual {
    revert StoreHook_NotImplemented();
  }
}
