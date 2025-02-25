// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { StoreRead } from "@latticexyz/store/src/StoreRead.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { IStoreData } from "@latticexyz/store/src/IStore.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Schema } from "@latticexyz/store/src/Schema.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";
import { FieldLayout } from "@latticexyz/store/src/FieldLayout.sol";

import { WORLD_VERSION } from "./version.sol";
import { System } from "./System.sol";
import { ResourceSelector } from "./ResourceSelector.sol";
import { ROOT_NAMESPACE, ROOT_NAME } from "./constants.sol";
import { AccessControl } from "./AccessControl.sol";
import { SystemCall } from "./SystemCall.sol";
import { WorldContextProvider } from "./WorldContext.sol";
import { revertWithBytes } from "./revertWithBytes.sol";
import { Delegation } from "./Delegation.sol";
import { requireInterface } from "./requireInterface.sol";

import { NamespaceOwner } from "./tables/NamespaceOwner.sol";
import { InstalledModules } from "./tables/InstalledModules.sol";
import { Delegations } from "./tables/Delegations.sol";

import { IModule, MODULE_INTERFACE_ID } from "./interfaces/IModule.sol";
import { IWorldKernel } from "./interfaces/IWorldKernel.sol";
import { IDelegationControl } from "./interfaces/IDelegationControl.sol";

import { Systems } from "./modules/core/tables/Systems.sol";
import { SystemHooks } from "./modules/core/tables/SystemHooks.sol";
import { FunctionSelectors } from "./modules/core/tables/FunctionSelectors.sol";
import { Balances } from "./modules/core/tables/Balances.sol";
import { CORE_MODULE_NAME } from "./modules/core/constants.sol";

contract World is StoreRead, IStoreData, IWorldKernel {
  using ResourceSelector for bytes32;
  address public immutable creator;

  function worldVersion() public pure returns (bytes32) {
    return WORLD_VERSION;
  }

  constructor() {
    creator = msg.sender;
    StoreCore.initialize();
    emit HelloWorld(WORLD_VERSION);
  }

  /**
   * Allows the creator of the World to initialize the World once.
   */
  function initialize(IModule coreModule) public {
    // Only the initial creator of the World can initialize it
    if (msg.sender != creator) {
      revert AccessDenied(ResourceSelector.from(ROOT_NAMESPACE).toString(), msg.sender);
    }

    // The World can only be initialized once
    if (InstalledModules._get(CORE_MODULE_NAME, keccak256("")) != address(0)) {
      revert WorldAlreadyInitialized();
    }

    // Initialize the World by installing the core module
    _installRootModule(coreModule, new bytes(0));
  }

  /**
   * Install the given root module in the World.
   * Requires the caller to own the root namespace.
   * The module is delegatecalled and installed in the root namespace.
   */
  function installRootModule(IModule module, bytes memory args) public {
    AccessControl.requireOwner(ROOT_NAMESPACE, msg.sender);
    _installRootModule(module, args);
  }

  function _installRootModule(IModule module, bytes memory args) internal {
    // Require the provided address to implement the IModule interface
    requireInterface(address(module), MODULE_INTERFACE_ID);

    WorldContextProvider.delegatecallWithContextOrRevert({
      msgSender: msg.sender,
      msgValue: 0,
      target: address(module),
      callData: abi.encodeCall(IModule.installRoot, (args))
    });

    // Register the module in the InstalledModules table
    InstalledModules._set(module.getName(), keccak256(args), address(module));
  }

  /************************************************************************
   *
   *    WORLD STORE METHODS
   *
   ************************************************************************/

  /**
   * Write a record in the table at the given tableId.
   * Requires the caller to have access to the table's namespace or name (encoded in the tableId).
   */
  function setRecord(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    bytes calldata staticData,
    PackedCounter encodedLengths,
    bytes calldata dynamicData,
    FieldLayout fieldLayout
  ) public virtual {
    // Require access to the namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Set the record
    StoreCore.setRecord(tableId, keyTuple, staticData, encodedLengths, dynamicData, fieldLayout);
  }

  function spliceStaticData(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    uint48 start,
    uint40 deleteCount,
    bytes calldata data
  ) public virtual {
    // Require access to the namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Splice the static data
    StoreCore.spliceStaticData(tableId, keyTuple, start, deleteCount, data);
  }

  function spliceDynamicData(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    bytes calldata data
  ) public virtual {
    // Require access to the namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Splice the dynamic data
    StoreCore.spliceDynamicData(tableId, keyTuple, dynamicFieldIndex, startWithinField, deleteCount, data);
  }

  /**
   * Write a field in the table at the given tableId.
   * Requires the caller to have access to the table's namespace or name (encoded in the tableId).
   */
  function setField(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    bytes calldata data,
    FieldLayout fieldLayout
  ) public virtual {
    // Require access to namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Set the field
    StoreCore.setField(tableId, keyTuple, fieldIndex, data, fieldLayout);
  }

  /**
   * Push data to the end of a field in the table at the given tableId.
   * Requires the caller to have access to the table's namespace or name (encoded in the tableId).
   */
  function pushToField(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    bytes calldata dataToPush,
    FieldLayout fieldLayout
  ) public virtual {
    // Require access to namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Push to the field
    StoreCore.pushToField(tableId, keyTuple, fieldIndex, dataToPush, fieldLayout);
  }

  /**
   * Pop data from the end of a field in the table at the given tableId.
   * Requires the caller to have access to the table's namespace or name (encoded in the tableId).
   */
  function popFromField(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    uint256 byteLengthToPop,
    FieldLayout fieldLayout
  ) public virtual {
    // Require access to namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Push to the field
    StoreCore.popFromField(tableId, keyTuple, fieldIndex, byteLengthToPop, fieldLayout);
  }

  /**
   * Update data at `startByteIndex` of a field in the table at the given tableId.
   * Requires the caller to have access to the table's namespace or name (encoded in the tableId).
   */
  function updateInField(
    bytes32 tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    uint256 startByteIndex,
    bytes calldata dataToSet,
    FieldLayout fieldLayout
  ) public virtual {
    // Require access to namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Update data in the field
    StoreCore.updateInField(tableId, keyTuple, fieldIndex, startByteIndex, dataToSet, fieldLayout);
  }

  /**
   * Delete a record in the table at the given tableId.
   * Requires the caller to have access to the namespace or name.
   */
  function deleteRecord(bytes32 tableId, bytes32[] calldata keyTuple, FieldLayout fieldLayout) public virtual {
    // Require access to namespace or name
    AccessControl.requireAccess(tableId, msg.sender);

    // Delete the record
    StoreCore.deleteRecord(tableId, keyTuple, fieldLayout);
  }

  /************************************************************************
   *
   *    SYSTEM CALLS
   *
   ************************************************************************/

  /**
   * Call the system at the given resourceSelector.
   * If the system is not public, the caller must have access to the namespace or name (encoded in the resourceSelector).
   */
  function call(bytes32 resourceSelector, bytes memory callData) external payable virtual returns (bytes memory) {
    return SystemCall.callWithHooksOrRevert(msg.sender, resourceSelector, callData, msg.value);
  }

  /**
   * Call the system at the given resourceSelector on behalf of the given delegator.
   * If the system is not public, the delegator must have access to the namespace or name (encoded in the resourceSelector).
   */
  function callFrom(
    address delegator,
    bytes32 resourceSelector,
    bytes memory callData
  ) external payable virtual returns (bytes memory) {
    // If the delegator is the caller, call the system directly
    if (delegator == msg.sender) {
      return SystemCall.callWithHooksOrRevert(msg.sender, resourceSelector, callData, msg.value);
    }

    // Check if there is an explicit authorization for this caller to perform actions on behalf of the delegator
    Delegation explicitDelegation = Delegation.wrap(Delegations._get({ delegator: delegator, delegatee: msg.sender }));

    if (explicitDelegation.verify(delegator, msg.sender, resourceSelector, callData)) {
      // forward the call as `delegator`
      return SystemCall.callWithHooksOrRevert(delegator, resourceSelector, callData, msg.value);
    }

    // Check if the delegator has a fallback delegation control set
    Delegation fallbackDelegation = Delegation.wrap(Delegations._get({ delegator: delegator, delegatee: address(0) }));
    if (fallbackDelegation.verify(delegator, msg.sender, resourceSelector, callData)) {
      // forward the call with `from` as `msgSender`
      return SystemCall.callWithHooksOrRevert(delegator, resourceSelector, callData, msg.value);
    }

    revert DelegationNotFound(delegator, msg.sender);
  }

  /************************************************************************
   *
   *    DYNAMIC FUNCTION SELECTORS
   *
   ************************************************************************/

  /**
   * ETH sent to the World without calldata is added to the root namespace's balance
   */
  receive() external payable {
    uint256 rootBalance = Balances._get(ROOT_NAMESPACE);
    Balances._set(ROOT_NAMESPACE, rootBalance + msg.value);
  }

  /**
   * Fallback function to call registered function selectors
   */
  fallback() external payable {
    (bytes32 resourceSelector, bytes4 systemFunctionSelector) = FunctionSelectors._get(msg.sig);

    if (resourceSelector == 0) revert FunctionSelectorNotFound(msg.sig);

    // Replace function selector in the calldata with the system function selector
    bytes memory callData = Bytes.setBytes4(msg.data, 0, systemFunctionSelector);

    // Call the function and forward the call data
    bytes memory returnData = SystemCall.callWithHooksOrRevert(msg.sender, resourceSelector, callData, msg.value);

    // If the call was successful, return the return data
    assembly {
      return(add(returnData, 0x20), mload(returnData))
    }
  }
}
