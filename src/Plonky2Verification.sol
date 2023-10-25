// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Plonky2Verification {
    // SuccinctX 0xpolygonzero/plonky2-evm integration.
    // From https://alpha.succinct.xyz/0xpolygonzero/plonky2-evm/integrate
    address public constant FUNCTION_GATEWAY = 0xE304f6B116bE5e43424cEC36a5eFd0B642E0dC95;
    bytes32 public constant FUNCTION_ID = 0xab5ee25ac7b527b26a990f4539ab99b231150f6b9ded1071e8107a37f1a58c93;

    uint256 public nextRequestId = 1;
    mapping(uint256 => Request) requests;

    struct Request {
        address sender;
        // Any additional request context needed can go here
        // (...)
    }

    PublicValues private dummyPublicValues;

    struct TrieRoots {
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptsRoot;
    }

    function serializeTrieRoots(
        TrieRoots memory trieRoots
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                trieRoots.stateRoot,
                trieRoots.transactionsRoot,
                trieRoots.receiptsRoot
            );
    }

    struct BlockMetadata {
        address blockBeneficiary;
        uint256 blockTimestamp;
        uint256 blockNumber;
        uint256 blockDifficulty;
        bytes32 blockRandom;
        uint256 blockGaslimit;
        uint256 blockChainId;
        uint256 blockBaseFee;
        uint256 blockGasUsed;
        uint256[8] blockBloom;
    }

    function serializeBlockMetadata(
        BlockMetadata memory blockMetadata
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                blockMetadata.blockBeneficiary,
                blockMetadata.blockTimestamp,
                blockMetadata.blockNumber,
                blockMetadata.blockDifficulty,
                blockMetadata.blockRandom,
                blockMetadata.blockGaslimit,
                blockMetadata.blockChainId,
                blockMetadata.blockBaseFee,
                blockMetadata.blockGasUsed,
                blockMetadata.blockBloom
            );
    }

    struct BlockHashes {
        bytes32[] prevHashes;
        bytes32 curHash;
    }

    function serializeBlockHashes(
        BlockHashes memory blockHashes
    ) public pure returns (bytes memory) {
        return abi.encodePacked(blockHashes.prevHashes, blockHashes.curHash);
    }

    struct ExtraBlockData {
        bytes32 genesisStateTrieRoot;
        uint256 txnNumberBefore;
        uint256 txnNumberAfter;
        uint256 gasUsedBefore;
        uint256 gasUsedAfter;
        uint256[8] blockBloomBefore;
        uint256[8] blockBloomAfter;
    }

    function serializeExtraBlockData(
        ExtraBlockData memory extraBlockData
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                extraBlockData.genesisStateTrieRoot,
                extraBlockData.txnNumberBefore,
                extraBlockData.txnNumberAfter,
                extraBlockData.gasUsedBefore,
                extraBlockData.gasUsedAfter,
                extraBlockData.blockBloomBefore,
                extraBlockData.blockBloomAfter
            );
    }

    struct PublicValues {
        TrieRoots trieRootsBefore;
        TrieRoots trieRootsAfter;
        BlockMetadata blockMetadata;
        BlockHashes blockHashes;
        ExtraBlockData extraBlockData;
    }

    function serializePublicValues(
        PublicValues memory publicValues
    ) public pure returns (bytes memory) {
        bytes memory serializedTrieRootsBefore = serializeTrieRoots(
            publicValues.trieRootsBefore
        );
        bytes memory serializedTrieRootsAfter = serializeTrieRoots(
            publicValues.trieRootsAfter
        );
        bytes memory serializedBlockMetadata = serializeBlockMetadata(
            publicValues.blockMetadata
        );
        bytes memory serializedBlockHashes = serializeBlockHashes(
            publicValues.blockHashes
        );
        bytes memory serializedExtraBlockData = serializeExtraBlockData(
            publicValues.extraBlockData
        );

        uint totalLength = serializedTrieRootsBefore.length +
            serializedTrieRootsAfter.length +
            serializedBlockMetadata.length +
            serializedBlockHashes.length +
            serializedExtraBlockData.length;

        bytes memory toReturn = new bytes(totalLength);

        uint counter = 0;
        for (uint i = 0; i < serializedTrieRootsBefore.length; i++) {
            toReturn[counter++] = serializedTrieRootsBefore[i];
        }
        for (uint i = 0; i < serializedTrieRootsAfter.length; i++) {
            toReturn[counter++] = serializedTrieRootsAfter[i];
        }
        for (uint i = 0; i < serializedBlockMetadata.length; i++) {
            toReturn[counter++] = serializedBlockMetadata[i];
        }
        for (uint i = 0; i < serializedBlockHashes.length; i++) {
            toReturn[counter++] = serializedBlockHashes[i];
        }
        for (uint i = 0; i < serializedExtraBlockData.length; i++) {
            toReturn[counter++] = serializedExtraBlockData[i];
        }

        return toReturn;
    }

    // Credit to https://ethereum.stackexchange.com/questions/7702/how-to-convert-byte-array-to-bytes32-in-solidity
    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function verifyProof() public {
        bytes memory serialized = serializePublicValues(dummyPublicValues);
    }

    // SuccinctX 0xpolygonzero/plonky2-evm integration.
    // From https://alpha.succinct.xyz/0xpolygonzero/plonky2-evm/integrate
    function request() external payable {
        uint256 requestId = nextRequestId++;
        requests[requestId] = Request(msg.sender);
        bytes memory input = serializePublicValues(dummyPublicValues);

        IFunctionGateway(FUNCTION_GATEWAY).request{value: msg.value}(
            FUNCTION_ID,
            input,
            this.handleCallback.selector,
            abi.encode(requestId)
        );
    }

    function handleCallback(bytes memory output, bytes memory context) external {
        require(msg.sender == FUNCTION_GATEWAY);
        uint256 requestId = abi.decode(context, (uint256));
        Request storage request = requests[requestId];
        // Process request here
        // (...)
        delete requests[requestId];
    }


    constructor() {
        TrieRoots memory dummyTrieRootsBefore = TrieRoots(
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0x92648889955b1d41b36ea681a16ef94852e34e6011d029f278439adb4e9e30b4
                    )
                )
            ),
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421
                    )
                )
            ),
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421
                    )
                )
            )
        );
        TrieRoots memory dummyTrieRootsAfter = TrieRoots(
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0x049e45aef8dac161e0cec0edacd8af5b3399700affad6ede63b33c5d0ec796f5
                    )
                )
            ),
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0xc523d7b87c0e49a24dae53b3e3be716e5a6808c1e05216497655c0ad84b12236
                    )
                )
            ),
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0xfc047c9c96ea3d317bf5b0896e85c242ecc625efd3f7da721c439aff8331b2ab
                    )
                )
            )
        );
        BlockMetadata memory dummyBlockMetadata = BlockMetadata(
            0x2ADC25665018Aa1FE0E6BC666DaC8Fc2697fF9bA,
            1000,
            0,
            131072,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            4478310,
            1,
            10,
            43570,
            [
                0,
                0,
                55213970774324510299479508399853534522527075462195808724319849722937344,
                1361129467683753853853498429727072845824,
                33554432,
                9223372036854775808,
                3618502788666131106986593281521497120414687020801267626233049500247285563392,
                2722259584404615024560450425766186844160
            ]
        );

        uint256 zero = 0x0;
        bytes32 encodedZero = bytesToBytes32(abi.encodePacked(zero));

        bytes32[] memory prevHashes = new bytes32[](256);
        for (uint256 i = 0; i < 256; i++) {
            prevHashes[i] = encodedZero;
        }
        BlockHashes memory dummyBlockHashes = BlockHashes(
            prevHashes,
            encodedZero
        );
        ExtraBlockData memory dummyExtraBlockData = ExtraBlockData(
            bytesToBytes32(
                abi.encodePacked(
                    uint256(
                        0x92648889955b1d41b36ea681a16ef94852e34e6011d029f278439adb4e9e30b4
                    )
                )
            ),
            0,
            2,
            0,
            43570,
            [zero, zero, zero, zero, zero, zero, zero, zero],
            [
                0,
                0,
                55213970774324510299479508399853534522527075462195808724319849722937344,
                1361129467683753853853498429727072845824,
                33554432,
                9223372036854775808,
                3618502788666131106986593281521497120414687020801267626233049500247285563392,
                2722259584404615024560450425766186844160
            ]
        );

        dummyPublicValues = PublicValues(
            dummyTrieRootsBefore,
            dummyTrieRootsAfter,
            dummyBlockMetadata,
            dummyBlockHashes,
            dummyExtraBlockData
        );
    }
}

// SuccinctX 0xpolygonzero/plonky2-evm integration.
// From https://alpha.succinct.xyz/0xpolygonzero/plonky2-evm/integrate
interface IFunctionGateway {
    function request(bytes32 functionId, bytes memory input, bytes4 callbackSelector, bytes memory context)
        external
        payable
        returns (bytes32);
}
