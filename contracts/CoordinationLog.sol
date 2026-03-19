// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CoordinationLog
 * @author Global Coordination Agent + Reis Mesquita
 * @notice On-chain log of AI coordination directives issued during disaster response.
 *         Deployed on Base Mainnet as part of The Synthesis Hackathon (March 2026).
 *
 * @dev Every time the Global Coordination Agent issues a directive during a crisis
 *      simulation, the directive is logged here permanently. This creates an auditable,
 *      immutable record of AI-human coordination decisions.
 *
 *      ERC-8004 agent identity: 0x1c5d132d0ec4533bed442a83859a574bff80dc9caed844ba31634250213c769f
 */
contract CoordinationLog {

    // ─── Events ───────────────────────────────────────────────────────────────

    event DirectiveIssued(
        uint256 indexed sessionId,
        uint256 indexed directiveNumber,
        string  fromUnit,
        string  toUnit,
        string  reasoning,
        uint256 estimatedLivesSaved,
        uint256 coordinationScore,
        uint256 timestamp
    );

    event SessionStarted(
        uint256 indexed sessionId,
        string  scenarioType,
        uint256 strikeCount,
        uint256 casualties,
        uint256 displaced,
        uint256 timestamp
    );

    event SessionCompleted(
        uint256 indexed sessionId,
        uint256 finalScore,
        uint256 totalLivesSaved,
        uint256 totalDirectives,
        uint256 responseTimeSeconds,
        uint256 timestamp
    );

    // ─── Structs ──────────────────────────────────────────────────────────────

    struct Directive {
        uint256 directiveNumber;
        string  fromUnit;
        string  toUnit;
        string  reasoning;
        uint256 estimatedLivesSaved;
        uint256 timestamp;
    }

    struct Session {
        uint256 sessionId;
        string  scenarioType;
        uint256 strikeCount;
        uint256 casualties;
        uint256 displaced;
        uint256 startTime;
        uint256 endTime;
        uint256 finalScore;
        uint256 totalLivesSaved;
        bool    completed;
        Directive[] directives;
    }

    // ─── State ────────────────────────────────────────────────────────────────

    address public immutable agent;         // ERC-8004 agent address
    address public immutable human;         // Human collaborator address
    string  public constant  agentName = "Global Coordination Agent";
    string  public constant  humanName = "Reis Mesquita";

    uint256 public sessionCount;
    mapping(uint256 => Session) public sessions;

    // ─── Constructor ──────────────────────────────────────────────────────────

    constructor(address _agent, address _human) {
        agent = _agent;
        human = _human;
    }

    // ─── Modifiers ────────────────────────────────────────────────────────────

    modifier onlyAuthorized() {
        require(
            msg.sender == agent || msg.sender == human,
            "CoordinationLog: unauthorized"
        );
        _;
    }

    // ─── Core Functions ───────────────────────────────────────────────────────

    /**
     * @notice Start a new coordination session (new disaster scenario)
     * @param scenarioType  Description of the scenario (e.g. "War Strike — City Alpha")
     * @param strikeCount   Number of strike events
     * @param casualties    Estimated casualties at session start
     * @param displaced     Estimated displaced civilians
     * @return sessionId    The ID of the new session
     */
    function startSession(
        string calldata scenarioType,
        uint256 strikeCount,
        uint256 casualties,
        uint256 displaced
    ) external onlyAuthorized returns (uint256 sessionId) {
        sessionId = ++sessionCount;
        Session storage s = sessions[sessionId];
        s.sessionId    = sessionId;
        s.scenarioType = scenarioType;
        s.strikeCount  = strikeCount;
        s.casualties   = casualties;
        s.displaced    = displaced;
        s.startTime    = block.timestamp;

        emit SessionStarted(sessionId, scenarioType, strikeCount, casualties, displaced, block.timestamp);
    }

    /**
     * @notice Log a coordination directive to the chain
     * @param sessionId             Active session ID
     * @param directiveNumber       Sequential number (1, 2, 3...)
     * @param fromUnit              Unit being redirected (e.g. "Rescue Team 3")
     * @param toUnit                Destination / target (e.g. "Hospital Alpha")
     * @param reasoning             Agent's reasoning for this directive
     * @param estimatedLivesSaved   Estimated lives saved by this specific directive
     */
    function logDirective(
        uint256 sessionId,
        uint256 directiveNumber,
        string  calldata fromUnit,
        string  calldata toUnit,
        string  calldata reasoning,
        uint256 estimatedLivesSaved
    ) external onlyAuthorized {
        Session storage s = sessions[sessionId];
        require(!s.completed, "CoordinationLog: session already completed");
        require(s.startTime > 0, "CoordinationLog: session does not exist");

        s.directives.push(Directive({
            directiveNumber:    directiveNumber,
            fromUnit:           fromUnit,
            toUnit:             toUnit,
            reasoning:          reasoning,
            estimatedLivesSaved: estimatedLivesSaved,
            timestamp:          block.timestamp
        }));

        emit DirectiveIssued(
            sessionId,
            directiveNumber,
            fromUnit,
            toUnit,
            reasoning,
            estimatedLivesSaved,
            0, // score updated at completion
            block.timestamp
        );
    }

    /**
     * @notice Mark a session as complete and record final metrics
     * @param sessionId          Session to complete
     * @param finalScore         Coordination score (0–100)
     * @param totalLivesSaved    Total estimated lives saved
     * @param responseTimeSeconds Time from activation to full coordination
     */
    function completeSession(
        uint256 sessionId,
        uint256 finalScore,
        uint256 totalLivesSaved,
        uint256 responseTimeSeconds
    ) external onlyAuthorized {
        Session storage s = sessions[sessionId];
        require(!s.completed, "CoordinationLog: already completed");
        require(s.startTime > 0, "CoordinationLog: session does not exist");

        s.completed       = true;
        s.endTime         = block.timestamp;
        s.finalScore      = finalScore;
        s.totalLivesSaved = totalLivesSaved;

        emit SessionCompleted(
            sessionId,
            finalScore,
            totalLivesSaved,
            s.directives.length,
            responseTimeSeconds,
            block.timestamp
        );
    }

    // ─── View Functions ───────────────────────────────────────────────────────

    /**
     * @notice Get all directives for a session
     */
    function getDirectives(uint256 sessionId) external view returns (Directive[] memory) {
        return sessions[sessionId].directives;
    }

    /**
     * @notice Get directive count for a session
     */
    function getDirectiveCount(uint256 sessionId) external view returns (uint256) {
        return sessions[sessionId].directives.length;
    }

    /**
     * @notice Get a summary of all sessions
     */
    function getSessionSummary(uint256 sessionId) external view returns (
        string  memory scenarioType,
        uint256 strikeCount,
        uint256 casualties,
        uint256 finalScore,
        uint256 totalLivesSaved,
        uint256 directiveCount,
        bool    completed
    ) {
        Session storage s = sessions[sessionId];
        return (
            s.scenarioType,
            s.strikeCount,
            s.casualties,
            s.finalScore,
            s.totalLivesSaved,
            s.directives.length,
            s.completed
        );
    }
}
