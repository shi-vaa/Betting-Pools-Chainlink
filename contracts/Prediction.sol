pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./utils/AccessProtected.sol";
import "./Price.sol";
import "./Feed.sol";

contract Prediction is AccessProtected, Feed, KeeperCompatible {
    using Address for address;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter public _betIds;

    IERC20 public immutable betsz;

    uint256 public lastTimeStamp = block.timestamp;

    enum MatchResult {
        YetToHappen,
        TeamA,
        TeamB,
        Drawn,
        Cancelled
    }

    struct Sport {
        string name;
        string matchResultUrl;
    }

    // Sport[] public sports;

    Sport[] public sports;

    struct Team {
        string name;
    }

    struct Match {
        uint8 sportId;
        uint16 season; //year
        uint8 teamAId;
        uint8 teamBId;
        uint256 betsStartTime;
        uint256 betsEndTime;
        uint256 endTime;
        MatchResult matchResult;
    }

    struct Pool {
        uint256[] matchIds;
        uint256 startTime;
        uint256 endTime;
        uint256 fee;
    }

    struct PoolPrediction {
        uint256[] matchIds;
        uint8[] teamIds;
        uint8 poolId;
        address predictor;
    }

    Pool[] public pools;

    PoolPrediction[] public predictions;

    // Address to poolId to Index of prediction
    mapping(address => mapping(uint256 => uint256))
        public predictionsIndexByPool;

    //sport to team ID
    mapping(uint8 => mapping(uint8 => Team)) public teams;

    mapping(uint256 => Match) public matches;

    // Mapping from sport to list of pending match Ids
    mapping(uint8 => uint256[]) public _sportToPendingMatchIds;

    // Mapping from match id to position in the pendingmatches array
    mapping(uint256 => uint256) public _pendingMatchesIndex;

    event TeamAdded(uint8 indexed sportId, uint8 indexed teamId, string team);

    event TeamUpdated(uint8 indexed sportId, uint8 indexed teamId, string team);

    event MatchAdded(
        uint8 indexed sport,
        uint16 indexed season,
        uint256 indexed matchId,
        uint8 _teamAId,
        uint8 _teamBId,
        uint256 _betsStartTime,
        uint256 _betsEndTime,
        uint256 _endTime
    );

    event SportAdded(uint8 indexed sportId, string name);

    event PoolAdded(
        uint256 indexed poolId,
        uint256[] matchIds,
        uint256 startTime,
        uint256 endTime,
        uint256 fee
    );

    event PoolPredicted(
        uint256 indexed predictionId,
        uint256[] matchIds,
        uint8[] teamIds,
        uint256 poolId,
        address predictor
    );

    // event BetPlaced(
    //     address user,
    //     uint256 indexed betIndex,
    //     uint256 poolId,
    //     uint256 indexed matchId,
    //     uint8 team
    // );

    event RewardedPools(uint256 poolId, address[] winners, uint256[] amount);

    event MatchResultAdded(uint256 indexed matchId, uint8 indexed wonTeamId);

    event PerformUpKeep(uint256 matchId);

    constructor(
        IERC20 _betsz,
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) Feed(_linkToken, _oracle, _jobId, _fee) {
        betsz = _betsz;
    }

    function updateOracleRequestParams(
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _fee
    ) external onlyAdmin {
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    function addSport(Sport calldata _sport) external onlyAdmin {
        require(
            bytes(_sport.name).length != 0 &&
                bytes(_sport.matchResultUrl).length != 0
        );
        sports.push(_sport);
        emit SportAdded(uint8(sports.length - 1), _sport.name);
    }

    function _updateSportUrl(uint8 _id, string calldata _url) internal {
        require(bytes(sports[_id].name).length != 0, "Invalid Sport Id");
        sports[_id].matchResultUrl = _url;
    }

    function addPool(Pool calldata _pool) external onlyAdmin {
        require(
            _pool.startTime >= block.timestamp &&
                _pool.endTime > block.timestamp &&
                _pool.startTime < _pool.endTime,
            "Invalid start/end time"
        );
        require(_pool.fee > 0, "Incorrect fee");
        for (uint256 i = 0; i < _pool.matchIds.length; i++) {
            uint256 matchId = _pool.matchIds[i];
            require(matches[matchId].betsStartTime != 0, "Match Not present");
        }
        pools.push(_pool);
        emit PoolAdded(
            pools.length - 1,
            _pool.matchIds,
            _pool.startTime,
            _pool.endTime,
            _pool.fee
        );
    }

    function getMatchIdsOfPool(uint256 _poolId)
        public
        view
        returns (uint256[] memory)
    {
        return pools[_poolId].matchIds;
    }

    function addTeams(
        uint8 _sportId,
        uint8 _teamId,
        Team calldata _team
    ) external onlyAdmin {
        require(bytes(sports[_sportId].name).length != 0);
        require(
            bytes(teams[_sportId][_teamId].name).length == 0,
            "Team Id already present"
        );
        teams[_sportId][_teamId] = _team;
        emit TeamAdded(_sportId, _teamId, _team.name);
    }

    function updateTeams(
        uint8 _sportId,
        uint8 _teamId,
        Team calldata _team
    ) external onlyAdmin {
        require(
            bytes(teams[_sportId][_teamId].name).length != 0,
            "Invalid team Id"
        );
        teams[_sportId][_teamId] = _team;
        emit TeamUpdated(_sportId, _teamId, _team.name);
    }

    function _addMatch(uint256 matchId, Match memory matchData) private {
        require(matches[matchId].betsStartTime == 0, "Match already added");
        require(matchData.teamAId != matchData.teamBId, "Team A == Team B");
        require(
            bytes(sports[matchData.sportId].name).length != 0,
            "Invalid Sport Id"
        );
        require(
            bytes(teams[matchData.sportId][matchData.teamAId].name).length !=
                0 &&
                bytes(teams[matchData.sportId][matchData.teamBId].name)
                    .length !=
                0,
            "Invalid Team ID"
        );
        require(
            matchData.betsStartTime >= block.timestamp &&
                matchData.betsEndTime > block.timestamp &&
                matchData.endTime > block.timestamp &&
                matchData.betsStartTime < matchData.betsEndTime,
            "Invalid start/end time"
        );
        matchData.matchResult = MatchResult.YetToHappen;
        matches[matchId] = matchData;
        _addMatchesToEnumeration(matchData.sportId, matchId);
        emit MatchAdded(
            matchData.sportId,
            matchData.season,
            matchId,
            matchData.teamAId,
            matchData.teamBId,
            matchData.betsStartTime,
            matchData.betsEndTime,
            matchData.endTime
        );
    }

    function addMatch(uint256 _matchId, Match calldata _matchData)
        external
        onlyAdmin
    {
        _addMatch(_matchId, _matchData);
    }

    function addMatches(uint256[] memory _matchIds, Match[] calldata _matchData)
        external
        onlyAdmin
    {
        require(
            _matchIds.length == _matchData.length,
            "matchIds.length != matchdata.length"
        );
        for (uint256 i = 0; i < _matchData.length; i++) {
            _addMatch(_matchIds[i], _matchData[i]);
        }
    }

    function _addMatchesToEnumeration(uint8 sportId, uint256 matchId) private {
        _pendingMatchesIndex[matchId] = _sportToPendingMatchIds[sportId].length;
        _sportToPendingMatchIds[sportId].push(matchId);
    }

    function _removeMatchFromEnumeration(uint8 sportId, uint256 matchId)
        private
    {
        uint256 lastMatchIndex = _sportToPendingMatchIds[sportId].length - 1;
        uint256 matchIndex = _pendingMatchesIndex[matchId];

        uint256 lastMatchId = _sportToPendingMatchIds[sportId][lastMatchIndex];

        _sportToPendingMatchIds[sportId][matchIndex] = lastMatchId;
        _pendingMatchesIndex[lastMatchId] = matchIndex;

        delete _pendingMatchesIndex[matchId];
        _sportToPendingMatchIds[sportId].pop();
    }

    function matchExistsInPool(uint256 _poolId, uint256 _matchId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pools[_poolId].matchIds.length; i++) {
            if (pools[_poolId].matchIds[i] == _matchId) {
                return true;
            }
        }
    }

    function addPoolPrediction(PoolPrediction calldata prediction) external {
        address sender = _msgSender();
        require(prediction.predictor == sender);
        require(
            prediction.matchIds.length == prediction.teamIds.length,
            "matchIds.length != teamIds.length"
        );
        require(pools[prediction.poolId].startTime > 0, "Invalid Pool Id");
        for (uint256 i = 0; i < prediction.matchIds.length; i++) {
            uint256 matchId = prediction.matchIds[i];
            require(
                matchExistsInPool(prediction.poolId, prediction.matchIds[i]),
                "Invalid match Id"
            );
            require(
                matches[matchId].teamAId == prediction.teamIds[i] ||
                    matches[matchId].teamBId == prediction.teamIds[i],
                "Invalid Team"
            );
        }
        require(
            pools[prediction.poolId].startTime <= block.timestamp &&
                pools[prediction.poolId].endTime >= block.timestamp,
            "Pools open/closed for Predictions"
        );
        require(
            predictionsIndexByPool[sender][prediction.poolId] == 0 &&
                (predictions[0].poolId != prediction.poolId ||
                    predictions[0].predictor != prediction.predictor),
            "Match Predicted"
        );
        predictions.push(prediction);
        predictionsIndexByPool[sender][prediction.poolId] =
            predictions.length -
            1;
        betsz.safeTransferFrom(
            sender,
            address(this),
            pools[prediction.poolId].fee
        );
        emit PoolPredicted(
            predictions.length - 1,
            prediction.matchIds,
            prediction.teamIds,
            prediction.poolId,
            sender
        );
    }

    // function placeBet(
    //     uint256 _poolId,
    //     uint256 _matchId,
    //     uint8 _team
    // ) external {
    //     require(
    //         matches[_matchId].teamAId == _team ||
    //             matches[_matchId].teamBId == _team,
    //         "Invalid Team"
    //     );
    //     require(matchExists(_poolId, _matchId), "Invalid match Id");
    //     require(
    //         matches[_matchId].betsStartTime <= block.timestamp &&
    //             matches[_matchId].betsEndTime > block.timestamp,
    //         "Match open/closed for Predictions"
    //     );
    //     require(
    //         pools[_poolId].startTime <= block.timestamp &&
    //             pools[_poolId].endTime >= block.timestamp,
    //         "Pools open/closed for bets"
    //     );
    //     address sender = _msgSender();
    //     for (uint256 i = 0; i < userBets[sender][_poolId].length; i++) {
    //         require(
    //             _matchId != userBets[sender][_poolId][i],
    //             "Match Predicted"
    //         );
    //     }
    //     userBets[sender][_poolId].push(_matchId);
    //     bets[_poolId].push(Bet(sender, _matchId, _team));
    //     if (userBets[sender][_poolId].length == 1) {
    //         betsz.safeTransferFrom(sender, address(this), pools[_poolId].fee);
    //     }
    //     emit BetPlaced(
    //         sender,
    //         bets[_poolId].length - 1,
    //         _poolId,
    //         _matchId,
    //         _team
    //     );
    // }

    function rewardPools(
        uint256 _poolId,
        address[] memory _winners,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(
            _winners.length == _amounts.length,
            "winners.length != _amounts.length"
        );
        require(pools[_poolId].endTime < block.timestamp, "Pool is still active");
        for (uint256 i = 0; i < _winners.length; i++) {
            address winner = _winners[i];
            uint256 amount = _amounts[i];
            betsz.transfer(winner, amount);
        }
        emit RewardedPools(_poolId, _winners, _amounts);
    }

    // function totalPredictionsByOwner(address _predictor)
    //     public
    //     view
    //     returns (uint256 counter)
    // {
    //     for (uint256 i = 0; i <= pools.length; i++) {
    //         if (
    //             predictionsIndexByPool[_predictor][i] > 0 ||
    //             (
    //                 (predictions[0].poolId == i &&
    //                     predictions[0].predictor == _predictor)
    //             )
    //         ) {
    //             counter++;
    //         }
    //     }
    // }

    // function allPredictionsByOwner(address _owner)
    //     external
    //     view
    //     returns (uint256[] memory)
    // {
    //     uint256 totalPredicts = totalPredictionsByOwner(_owner);
    //     uint256[] memory result = new uint256[](totalPredicts);
    //     uint256 counter = 0;
    //     for (uint256 i = 0; i < pools.length; i++) {
    //         for (uint256 j = 0; j < bets[i].length; j++) {
    //             if (bets[i][j].placerAddress == _owner) {
    //                 result[counter] = j; //useless
    //                 counter++;
    //             }
    //         }
    //     }
    //     return result;
    // }

    // function totalPredictionsByPool(uint256 _poolId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return bets[_poolId].length;
    // }

    // function totalPredictionsOfOwnerByPool(address _owner, uint256 _poolId)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return userBets[_owner][_poolId].length;
    // }

    // function allPredictionsOfOwnerByPool(address _owner, uint256 _poolId)
    //     public
    //     view
    //     returns (uint256[] memory)
    // {
    //     uint256 totalPredicts = totalPredictionsOfOwnerByPool(_owner, _poolId);
    //     uint256[] memory result = new uint256[](totalPredicts);
    //     uint256 counter = 0;
    //     for (uint256 i = 0; i < bets[_poolId].length; i++) {
    //         if (bets[_poolId][i].placerAddress == _owner) {
    //             result[counter] = i; //useless
    //             counter++;
    //         }
    //     }
    //     return result;
    // }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        // uint256 endingMatchId;
        // uint256 endTimeStamp;
        for (uint8 i = 0; i < sports.length; i++) {
            for (uint256 j = 0; j < _sportToPendingMatchIds[i].length; j++) {
                uint256 matchId = _sportToPendingMatchIds[i][j];
                if (
                    block.timestamp > matches[matchId].endTime &&
                    block.timestamp - lastTimeStamp > 120
                ) {
                    upkeepNeeded = true;
                    performData = abi.encode(matchId);
                    return (upkeepNeeded, performData);
                }
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 matchId = abi.decode(performData, (uint256));
        uint8 sportId = matches[matchId].sportId;
        string memory url = matchResultUrl(
            sports[sportId].matchResultUrl,
            matchId
        );
        lastTimeStamp = block.timestamp;
        requestMatchResult(url, matchId, this.fulfill.selector);
        _removeMatchFromEnumeration(matches[matchId].sportId, matchId);
        emit PerformUpKeep(matchId);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, bool _winner)
        public
        recordChainlinkFulfillment(_requestId)
    {
        uint256 matchId = requestMatchId[_requestId];
        uint8 wonTeamId;
        if (_winner) {
            matches[matchId].matchResult = MatchResult.TeamA;
            wonTeamId = matches[matchId].teamAId;
        } else {
            matches[matchId].matchResult = MatchResult.TeamB;
            wonTeamId = matches[matchId].teamBId;
        }
        emit MatchResultAdded(matchId, wonTeamId);
    }
}
