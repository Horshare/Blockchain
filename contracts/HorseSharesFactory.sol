// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HorseRegistry.sol";
import "./HorseShareToken.sol";

/**
 * HorseSharesFactory
 * - Cria o ERC-20 de cotas para cada cavalo (por horseTokenId)
 * - Regra padrão do MVP: só o dono do NFT (cavalo) pode criar as cotas
 * - Mantém mappings:
 *    - horseTokenId => shareToken
 *    - dbHorseId => shareToken (facilita integração com o backend)
 */
contract HorseSharesFactory {
    HorseRegistry public immutable registry;

    mapping(uint256 => address) public shareTokenOfHorseTokenId; // horseTokenId => ERC20
    mapping(uint256 => address) public shareTokenOfDbHorseId;    // dbHorseId => ERC20

    event SharesCreated(
        uint256 indexed horseTokenId,
        uint256 indexed dbHorseId,
        address shareToken,
        uint256 totalSupply,
        address initialOwner
    );

    constructor(address registry_) {
        registry = HorseRegistry(registry_);
    }

    function createShares(
        uint256 horseTokenId,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply
    ) external returns (address) {
        require(totalSupply > 0, "Invalid supply");
        require(shareTokenOfHorseTokenId[horseTokenId] == address(0), "Shares already exist");
        require(registry.isActive(horseTokenId), "Horse inactive");

        address horseOwner = registry.ownerOf(horseTokenId);
        require(msg.sender == horseOwner, "Not horse owner");

        uint256 dbHorseId = registry.dbHorseIdOfToken(horseTokenId);
        require(dbHorseId != 0, "Missing dbHorseId");
        require(shareTokenOfDbHorseId[dbHorseId] == address(0), "DB horse shares already exist");

        HorseShareToken token = new HorseShareToken(
            name_,
            symbol_,
            horseTokenId,
            dbHorseId,
            address(this)
        );

        // Mint inicial para o dono do cavalo (pode trocar por um Vault no futuro)
        token.mint(horseOwner, totalSupply);

        shareTokenOfHorseTokenId[horseTokenId] = address(token);
        shareTokenOfDbHorseId[dbHorseId] = address(token);

        emit SharesCreated(horseTokenId, dbHorseId, address(token), totalSupply, horseOwner);
        return address(token);
    }
}
