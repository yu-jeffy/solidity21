// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract 21solidity {
    uint8 constant private MAX_PLAYERS = 5;

    address public owner;
    uint256 public minimumBet;
    uint256 public totalBets;

    struct Player {
        uint256 bet;
        uint8[] hand;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    enum GameState {NotStarted, InProgress, Finished}
    GameState public gameState;

    constructor(uint256 _minimumBet) {
        owner = msg.sender;
        minimumBet = _minimumBet;
        gameState = GameState.NotStarted;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier notInProgress() {
        require(gameState != GameState.InProgress, "Game is currently in progress.");
        _;
    }

    function joinGame() public payable notInProgress {
        require(playerAddresses.length < MAX_PLAYERS, "Maximum number of players reached.");
        require(players[msg.sender].bet == 0, "You have already joined.");
        require(msg.value >= minimumBet, "You did not send enough ether.");

        players[msg.sender].bet = msg.value;
        playerAddresses.push(msg.sender);
    }

    function startGame() public onlyOwner notInProgress {
        require(playerAddresses.length > 0, "There are no players in the game.");
        gameState = GameState.InProgress;

        // Deal the initial cards to each player
        for (uint8 i = 0; i < playerAddresses.length; i++) {
            players[playerAddresses[i]].hand = _getInitialHand();
        }
    }

    function hit() public {
        require(players[msg.sender].bet > 0, "You are not in the game.");
        require(gameState == GameState.InProgress, "Game is not in progress.");
        players[msg.sender].hand.push(_getRandomCard());
    }

    function stand() public {
        require(players[msg.sender].bet > 0, "You are not in the game.");
        require(gameState == GameState.InProgress, "Game is not in progress.");
        
        uint8 playerScore = _getScore(players[msg.sender].hand);

        if (playerScore > 21) {
            lose();
        } else {
            uint8 dealerScore = _getDealerScore();

            if (dealerScore > 21 || playerScore > dealerScore) {
                win();
            } else if (dealerScore == playerScore) {
                draw();
            } else {
                lose();
            }
        }
    }

    function win() private {
        uint256 winnings = players[msg.sender].bet * 2;
        totalBets -= winnings;

        (bool success, ) = msg.sender.call{value: winnings}("");
        require(success, "Transfer of winnings failed.");

        resetPlayer(msg.sender);
    }

    function draw() private {
        uint256 bet = players[msg.sender].bet;
        (bool success, ) = msg.sender.call{value: bet}("");
        require(success, "Transfer of bet failed.");

        resetPlayer(msg.sender);
    }

    function lose() private {
        totalBets += players[msg.sender].bet;
        resetPlayer(msg.sender);
    }

    function resetPlayer(address player) private {
        delete players[player].hand;
        players[player].bet = 0;
    }

    function _getDealerScore() private view returns (uint8) {
        uint8 dealerScore = 17 + _getRandomCard() % 5; // Assuming the dealer stands on a soft 17
        return dealerScore;
    }

    function _getInitialHand() private view returns (uint8[] memory) {
        uint8 card1 = _getRandomCard();
        uint8 card2 = _getRandomCard();
        uint8[] memory hand = new uint8[](2);
        hand[0] = card1;
        hand[1] = card2;

        return hand;
    }

    function _getRandomCard() private view returns (uint8) {
        uint8 card = uint8((uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 13) + 1);
        return card;
    }

    function _getScore(uint8[] memory hand) private pure returns (uint8) {
        uint8 score = 0;
        uint8 aces = 0;

        for (uint8 i = 0; i < hand.length; i++) {
            uint8 cardScore = hand[i] > 10 ? 10 : hand[i];

            if (cardScore == 1) {
                aces++;
            }

            score += cardScore;
        }

        for (uint8 i = 0; i < aces; i++) {
            if (score + 10 <= 21) {
                score += 10;
            }
        }

        return score;
    }
}