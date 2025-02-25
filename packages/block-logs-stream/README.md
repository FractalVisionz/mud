# Block logs stream

A set of utilities for efficiently retrieving blockchain event logs. Built on top of [viem][0] and [RxJS][1].

[0]: https://viem.sh/
[1]: https://rxjs.dev/

## Example

```ts
import { filter, map, mergeMap } from "rxjs";
import { createPublicClient, parseAbi } from "viem";
import { createBlockStream, groupLogsByBlockNumber, blockRangeToLogs } from "@latticexyz/block-logs-stream";

const publicClient = createPublicClient({
  // your viem public client config here
});

const latestBlock$ = await createBlockStream({ publicClient, blockTag: "latest" });
const latestBlockNumber$ = latestBlock$.pipe(map((block) => block.number));

latestBlockNumber$
  .pipe(
    map((latestBlockNumber) => ({ startBlock: 0n, endBlock: latestBlockNumber })),
    blockRangeToLogs({
      publicClient,
      address,
      events: parseAbi([
        "event StoreDeleteRecord(bytes32 tableId, bytes32[] keyTuple)",
        "event StoreSetField(bytes32 tableId, bytes32[] keyTuple, uint8 schemaIndex, bytes data)",
        "event StoreSetRecord(bytes32 tableId, bytes32[] keyTuple, bytes data)",
        "event StoreEphemeralRecord(bytes32 tableId, bytes32[] keyTuple, bytes data)",
      ]),
    }),
    mergeMap(({ logs }) => from(groupLogsByBlockNumber(logs)))
  )
  .subscribe((block) => {
    console.log("got events for block", block);
  });
```
