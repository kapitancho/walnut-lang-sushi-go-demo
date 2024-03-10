class Client {
	/**
	 * @param {ServerProxy} serverProxy
	 */
	constructor(serverProxy) {
		this.serverProxy = serverProxy;
	}

	async tableList() {
		return (await this.serverProxy.apiCall('/playroom/tables', 'GET',
			null, [200]))?.json;
	}

	async table(tableNumber) {
		return (await this.serverProxy.apiCall(`/playroom/tables/${tableNumber}`, 'GET',
			null, [200]))?.json;
	}

	async gameOnTable(tableNumber) {
		return (await this.serverProxy.apiCall(`/playroom/tables/${tableNumber}/game`, 'GET',
			null, [200]))?.json;
	}

	async gameList() {
		return (await this.serverProxy.apiCall('/playroom/games', 'GET',
			null, [200]))?.json;
	}

	async game(gameId) {
		return (await this.serverProxy.apiCall(`/playroom/games/${gameId}`, 'GET',
			null, [200]))?.json;
	}

	async playerGame(gameId, playerId) {
		return (await this.serverProxy.apiCall(`/playroom/games/${gameId}/players/${playerId}`, 'GET',
			null, [200]))?.json;
	}

	async playMove(gameId, playerId, chosenCard, chopsticksExchange) {
		return (await this.serverProxy.apiCall(`/playroom/games/${gameId}/players/${playerId}/card`, 'POST',
			JSON.stringify({chosenCard, chopsticksExchange}), [204]))?.json;
	}

	async newTable(minPlayers, maxPlayers) {
		return (await this.serverProxy.apiCall('/playroom/tables', 'POST',
			JSON.stringify({playersCountRange: {minPlayers, maxPlayers}}), [201]))?.location;
	}

	async joinTable(tableNumber, playerName) {
		return (await this.serverProxy.apiCall(`/playroom/tables/${tableNumber}/players`, 'POST',
			JSON.stringify({playerName}), [201]))?.location;
	}

	async leaveTable(tableNumber, playerId) {
		return (await this.serverProxy.apiCall(`/playroom/tables/${tableNumber}/players/${playerId}`, 'DELETE',
			null,  [204]));
	}

	async startGame(tableNumber) {
		return (await this.serverProxy.apiCall(`/playroom/tables/${tableNumber}/game`, 'POST',
			null, [201]))?.json;
	}

}

export default Client;