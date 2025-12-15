// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * HorseShareToken (ERC-20)
 * - 1 instância = cotas de 1 cavalo (1 tokenId do ERC-721)
 * - Mint controlado pela Factory (MINTER_ROLE)
 * - Pause para compliance / emergências
 */
contract HorseShareToken is ERC20, AccessControl, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public immutable horseTokenId; // tokenId do HorseRegistry (ERC-721)
    uint256 public immutable dbHorseId;    // cavalo.id no banco (conveniência)

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 horseTokenId_,
        uint256 dbHorseId_,
        address factory
    ) ERC20(name_, symbol_) {
        horseTokenId = horseTokenId_;
        dbHorseId = dbHorseId_;

        _grantRole(DEFAULT_ADMIN_ROLE, factory);
        _grantRole(MINTER_ROLE, factory);
        _grantRole(PAUSER_ROLE, factory);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    // Bloqueia transfers quando pausado
    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }
}
