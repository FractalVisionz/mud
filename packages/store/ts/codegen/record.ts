import {
  RenderDynamicField,
  renderArguments,
  renderCommonData,
  renderList,
  renderWithStore,
} from "@latticexyz/common/codegen";
import { renderDecodeValueType } from "./field";
import { RenderTableOptions } from "./types";

export function renderRecordMethods(options: RenderTableOptions) {
  const { structName, storeArgument } = options;
  const { _tableId, _typedTableId, _keyArgs, _typedKeyArgs, _keyTupleDefinition } = renderCommonData(options);

  let result = renderWithStore(
    storeArgument,
    (_typedStore, _store, _commentSuffix, _untypedStore, _methodNamePrefix) => `
      /** Get the full data${_commentSuffix} */
      function ${_methodNamePrefix}get(${renderArguments([
      _typedStore,
      _typedTableId,
      _typedKeyArgs,
    ])}) internal view returns (${renderDecodedRecord(options)}) {
        ${_keyTupleDefinition}

        (
          bytes memory _staticData,
          PackedCounter _encodedLengths,
          bytes memory _dynamicData
        ) = ${_store}.getRecord(_tableId, _keyTuple, _fieldLayout);
        return decode(_staticData, _encodedLengths, _dynamicData);
      }
    `
  );

  result += renderWithStore(
    storeArgument,
    (_typedStore, _store, _commentSuffix, _untypedStore, _methodNamePrefix) => `
      /** Set the full data using individual values${_commentSuffix} */
      function ${_methodNamePrefix}set(${renderArguments([
      _typedStore,
      _typedTableId,
      _typedKeyArgs,
      renderArguments(options.fields.map(({ name, typeWithLocation }) => `${typeWithLocation} ${name}`)),
    ])}) internal {
        ${renderRecordData(options)}

        ${_keyTupleDefinition}

        ${_store}.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
      }
    `
  );

  if (structName !== undefined) {
    result += renderWithStore(
      storeArgument,
      (_typedStore, _store, _commentSuffix, _untypedStore, _methodNamePrefix) => `
        /** Set the full data using the data struct${_commentSuffix} */
        function ${_methodNamePrefix}set(${renderArguments([
        _typedStore,
        _typedTableId,
        _typedKeyArgs,
        `${structName} memory _table`,
      ])}) internal {
          set(${renderArguments([
            _untypedStore,
            _tableId,
            _keyArgs,
            renderArguments(options.fields.map(({ name }) => `_table.${name}`)),
          ])});
        }
      `
    );
  }

  result += renderDecodeFunctions(options);

  return result;
}

export function renderRecordData(options: RenderTableOptions) {
  let result = "";
  if (options.staticFields.length > 0) {
    result += `
      bytes memory _staticData = encodeStatic(${renderArguments(options.staticFields.map(({ name }) => name))});
    `;
  } else {
    result += `bytes memory _staticData;`;
  }

  if (options.dynamicFields.length > 0) {
    result += `
      PackedCounter _encodedLengths = encodeLengths(${renderArguments(options.dynamicFields.map(({ name }) => name))});
      bytes memory _dynamicData = encodeDynamic(${renderArguments(options.dynamicFields.map(({ name }) => name))});
    `;
  } else {
    result += `
      PackedCounter _encodedLengths;
      bytes memory _dynamicData;
    `;
  }

  return result;
}

// Renders the `decode` function that parses a bytes blob into the table data
function renderDecodeFunctions({ structName, fields, staticFields, dynamicFields }: RenderTableOptions) {
  // either set struct properties, or just variables
  const renderedDecodedRecord = structName
    ? `${structName} memory _table`
    : renderArguments(fields.map(({ name, typeWithLocation }) => `${typeWithLocation} ${name}`));
  const fieldNamePrefix = structName ? "_table." : "";

  // Static field offsets
  const staticOffsets = staticFields.map(() => 0);
  let _acc = 0;
  for (const [index, field] of staticFields.entries()) {
    staticOffsets[index] = _acc;
    _acc += field.staticByteLength;
  }

  let result = "";

  if (staticFields.length > 0) {
    result += `
      /**
       * Decode the tightly packed blob of static data using this table's field layout
       * Undefined behaviour for invalid blobs
       */
      function decodeStatic(bytes memory _blob) internal pure returns (${renderArguments(
        staticFields.map(({ name, typeWithLocation }) => `${typeWithLocation} ${name}`)
      )}) {
        ${renderList(
          staticFields,
          (field, index) => `
          ${field.name} = ${renderDecodeValueType(field, staticOffsets[index])};
          `
        )}
      }
    `;
  }

  if (dynamicFields.length > 0) {
    result += `
      /**
       * Decode the tightly packed blob of static data using this table's field layout
       * Undefined behaviour for invalid blobs
       */
      function decodeDynamic(PackedCounter _encodedLengths, bytes memory _blob) internal pure returns (${renderArguments(
        dynamicFields.map(({ name, typeWithLocation }) => `${typeWithLocation} ${name}`)
      )}) {
        ${renderList(
          dynamicFields,
          // unchecked is only dangerous if _encodedLengths (and _blob) is invalid,
          // but it's assumed to be valid, and this function is meant to be mostly used internally
          (field, index) => {
            if (index === 0) {
              return `
                uint256 _start;
                uint256 _end;
                unchecked {
                  _end = _encodedLengths.atIndex(${index});
                }
                ${field.name} = ${renderDecodeDynamicFieldPartial(field)};
              `;
            } else {
              return `
                _start = _end;
                unchecked {
                  _end += _encodedLengths.atIndex(${index});
                }
                ${field.name} = ${renderDecodeDynamicFieldPartial(field)};
              `;
            }
          }
        )}
      }
    `;
  }

  result += `
    /**
     * Decode the tightly packed blob using this table's field layout.
     * Undefined behaviour for invalid blobs.
     */
    function decode(
      bytes memory ${staticFields.length > 0 ? "_staticData" : ""},
      PackedCounter ${dynamicFields.length > 0 ? "_encodedLengths" : ""},
      bytes memory ${dynamicFields.length > 0 ? "_dynamicData" : ""}
    ) internal pure returns (${renderedDecodedRecord}) {
  `;

  if (staticFields.length > 0) {
    result += `
      (${renderArguments(staticFields.map((field) => `${fieldNamePrefix}${field.name}`))}) = decodeStatic(_staticData);
    `;
  }
  if (dynamicFields.length > 0) {
    result += `
      (${renderArguments(
        dynamicFields.map((field) => `${fieldNamePrefix}${field.name}`)
      )}) = decodeDynamic(_encodedLengths, _dynamicData);
    `;
  }

  result += `
    }
  `;

  return result;
}

// contents of `returns (...)` for record getter/decoder
function renderDecodedRecord({ structName, fields }: RenderTableOptions) {
  if (structName) {
    return `${structName} memory _table`;
  } else {
    return renderArguments(fields.map(({ name, typeWithLocation }) => `${typeWithLocation} ${name}`));
  }
}

function renderDecodeDynamicFieldPartial(field: RenderDynamicField) {
  const { typeId, arrayElement, typeWrap } = field;
  if (arrayElement) {
    // arrays
    return `${typeWrap}(
      SliceLib.getSubslice(_blob, _start, _end).decodeArray_${arrayElement.typeId}()
    )`;
  } else {
    // bytes/string
    return `${typeWrap}(
      ${typeId}(
        SliceLib.getSubslice(_blob, _start, _end).toBytes()
      )
    )`;
  }
}
