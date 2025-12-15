// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract HorseRegistry is ERC721URIStorage, AccessControl, Pausable {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public nextTokenId;

    // tokenId => ativo?
    mapping(uint256 => bool) public isActive;

    // tokenId => dbHorseId (cavalo.id)
    mapping(uint256 => uint256) public dbHorseIdOfToken;

    // tokenId => hash(microchip)
    mapping(uint256 => bytes32) public microchipHashOfToken;

    // tokenId => hash do registro/mensuração mais recente
    mapping(uint256 => bytes32) public latestRegistroHashOfToken;

    // dbHorseId => tokenId (dedupe)
    mapping(uint256 => uint256) public tokenOfDbHorseId;

    // microchipHash => tokenId (dedupe)
    mapping(bytes32 => uint256) public tokenOfMicrochipHash;

    event HorseMinted(
        uint256 indexed tokenId,
        uint256 indexed dbHorseId,
        bytes32 indexed microchipHash,
        address owner,
        string tokenURI,
        bytes32 registroHash
    );

    event RegistroHashUpdated(
        uint256 indexed tokenId,
        bytes32 oldHash,
        bytes32 newHash,
        string tipo
    );

    event HorseStatusChanged(uint256 indexed tokenId, bool isActive);
    event HorseTokenURIUpdated(uint256 indexed tokenId, string newTokenURI);

    constructor(address admin) ERC721("Horshare Horse", "HSHORSE") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    /**
     * Mint do NFT do cavalo a partir do banco.
     *
     * @param to Dono inicial (smart account do usuário)
     * @param dbHorseId PK do cavalo no banco (cavalo.id)
     * @param microchipHash keccak256(bytes(microchip_normalizado))
     * @param registroHash keccak256(bytes(canonicalJson(registro+mensuracao+...)))
     * @param tokenURI ipfs://... ou https://... do metadata do cavalo (sem PII)
     */
    function mintHorseFromDb(
        address to,
        uint256 dbHorseId,
        bytes32 microchipHash,
        bytes32 registroHash,
        string memory tokenURI
    ) external onlyRole(REGISTRAR_ROLE) whenNotPaused returns (uint256) {
        require(to != address(0), "Invalid owner");
        require(dbHorseId != 0, "Invalid dbHorseId");
        require(microchipHash != bytes32(0), "Invalid microchipHash");
        require(registroHash != bytes32(0), "Invalid registroHash");

        // Deduplicação alinhada ao schema:
        // - cavalo.id é PK
        require(tokenOfDbHorseId[dbHorseId] == 0, "DB horse already minted");
        // - microchip é UNIQUE
        require(tokenOfMicrochipHash[microchipHash] == 0, "Microchip already minted");

        uint256 tokenId = ++nextTokenId;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        isActive[tokenId] = true;

        dbHorseIdOfToken[tokenId] = dbHorseId;
        microchipHashOfToken[tokenId] = microchipHash;
        latestRegistroHashOfToken[tokenId] = registroHash;

        tokenOfDbHorseId[dbHorseId] = tokenId;
        tokenOfMicrochipHash[microchipHash] = tokenId;

        emit HorseMinted(tokenId, dbHorseId, microchipHash, to, tokenURI, registroHash);
        return tokenId;
    }

    /**
     * Atualiza a âncora do registro/mensuração (ex.: provisório -> definitivo).
     * Mantemos apenas o hash mais recente em storage; o histórico fica via eventos.
     */
    function updateRegistroHash(
        uint256 tokenId,
        bytes32 newRegistroHash,
        string memory tipo
    ) external onlyRole(REGISTRAR_ROLE) whenNotPaused {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(newRegistroHash != bytes32(0), "Invalid hash");

        bytes32 oldHash = latestRegistroHashOfToken[tokenId];
        latestRegistroHashOfToken[tokenId] = newRegistroHash;

        emit RegistroHashUpdated(tokenId, oldHash, newRegistroHash, tipo);
    }

    /**
     * Opcional: permitir atualização do tokenURI quando houver novos docs/metadata
     * (mantendo um hash imutável separado para integridade).
     */
    function updateTokenURI(uint256 tokenId, string memory newTokenURI)
        external
        onlyRole(REGISTRAR_ROLE)
        whenNotPaused
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _setTokenURI(tokenId, newTokenURI);
        emit HorseTokenURIUpdated(tokenId, newTokenURI);
    }

    function setActive(uint256 tokenId, bool active)
        external
        onlyRole(REGISTRAR_ROLE)
        whenNotPaused
    {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        isActive[tokenId] = active;
        emit HorseStatusChanged(tokenId, active);
    }

    function pause() external onlyRole(PAUSER_ROLE) { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    // Bloqueia transferências quando pausado
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Usamos isso para bloquear transferências quando pausado.
    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override
        whenNotPaused
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

}
