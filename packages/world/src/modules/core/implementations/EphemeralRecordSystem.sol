// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IStoreEphemeral } from "@latticexyz/store/src/IStore.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";
import { System } from "../../../System.sol";
import { ResourceSelector } from "../../../ResourceSelector.sol";
import { AccessControl } from "../../../AccessControl.sol";

contract EphemeralRecordSystem is IStoreEphemeral, System {
  using ResourceSelector for bytes32;

  /**
   * Emit the ephemeral event without modifying storage at the given namespace and name.
   * Requires the caller to have access to the namespace or name (encoded in the resource selector)
   */
  function emitEphemeralRecord(
    bytes32 resourceSelector,
    bytes32[] calldata keyTuple,
    bytes calldata staticData,
    PackedCounter encodedLengths,
    bytes calldata dynamicData,
    FieldLayout fieldLayout
  ) public virtual {
    // Require access to the namespace or name
    AccessControl.requireAccess(resourceSelector, msg.sender);

    // Set the record
    StoreCore.emitEphemeralRecord(resourceSelector, keyTuple, staticData, encodedLengths, dynamicData, fieldLayout);
  }
}
