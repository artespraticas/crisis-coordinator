// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract CoordinationLog {
    event SessionStarted(uint256 indexed sessionId, string scenarioType, uint256 timestamp);
    event DirectiveIssued(uint256 indexed sessionId, uint256 directiveNumber, string fromUnit, string toUnit, string reasoning, uint256 timestamp);
    event SessionCompleted(uint256 indexed sessionId, uint256 finalScore, uint256 livesSaved, uint256 timestamp);

    struct Session { uint256 id; string scenarioType; uint256 startTime; uint256 finalScore; uint256 livesSaved; bool completed; }
    
    address public owner;
    uint256 public sessionCount;
    mapping(uint256 => Session) public sessions;
    string public constant agentName = "Global Coordination Agent";
    string public constant humanName = "Reis Mesquita";

    constructor() { owner = msg.sender; }

    function startSession(string calldata scenarioType) external returns (uint256) {
        uint256 id = ++sessionCount;
        sessions[id] = Session(id, scenarioType, block.timestamp, 0, 0, false);
        emit SessionStarted(id, scenarioType, block.timestamp);
        return id;
    }

    function logDirective(uint256 sessionId, uint256 num, string calldata fromUnit, string calldata toUnit, string calldata reasoning) external {
        require(sessions[sessionId].startTime > 0, "no session");
        emit DirectiveIssued(sessionId, num, fromUnit, toUnit, reasoning, block.timestamp);
    }

    function completeSession(uint256 sessionId, uint256 score, uint256 livesSaved) external {
        Session storage s = sessions[sessionId];
        require(s.startTime > 0, "no session");
        s.finalScore = score; s.livesSaved = livesSaved; s.completed = true;
        emit SessionCompleted(sessionId, score, livesSaved, block.timestamp);
    }
}
