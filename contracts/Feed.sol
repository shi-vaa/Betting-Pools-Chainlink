// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Feed is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    mapping(bytes32 => uint256) public requestMatchId;

    address internal oracle;
    bytes32 internal jobId;
    uint256 internal fee;

    /**
     * Oracle:
     * Job ID:
     * Fee: s
     */
    constructor(
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) {
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function matchResultUrl(string memory _baseUrl, uint256 _matchId)
        public
        pure
        returns (string memory)
    {
        string memory matchId = Strings.toString(_matchId);
        return
            string(
                bytes.concat(
                    bytes(_baseUrl),
                    bytes(matchId),
                    bytes("/competitions/"),
                    bytes(matchId),
                    bytes("?lang=en&region=us")
                )
            );
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     */
    function requestMatchResult(
        string memory _url,
        uint256 _matchId,
        bytes4 _fulfillCallbackSelector
    ) public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            _fulfillCallbackSelector
        );

        request.add("get", _url);

        request.add("path", "competitors.0.winner");

        requestId = sendChainlinkRequestTo(oracle, request, fee);

        requestMatchId[requestId] = _matchId;

        return requestId;
    }
}
