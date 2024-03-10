import clientProxy from './boot.js';

export default async function (container) {
	let nameEl = document.querySelector('#name');
	nameEl.value = localStorage.getItem('name') || '';
	nameEl.addEventListener('change', () => {
		localStorage.setItem('name', nameEl.value);
	});
	let newLi = document.createElement('li');
	let fn = async () => {
		let gameId = localStorage.getItem('gameId');
		container.hidden = !!gameId;
		if (gameId) {
			return;
		}
		let tables = await clientProxy.tableList();
		if (!tables) {
			return;
		}
		while(container && container.firstChild !== newLi) container.firstChild.remove();

		let currentTable = parseInt(localStorage.getItem('tableNumber')) || 0;
		let nameExists = nameEl.value !== '';
		tables.forEach(table => {
			if (currentTable && table.number === currentTable && table.currentGame) {
				localStorage.setItem('gameId', table.currentGame.id);
			}
			let li = document.createElement('li');
			li.innerHTML = `Table <strong>${table.number}</strong>` +
				` (${table.playersCount.minPlayers} - ${table.playersCount.maxPlayers}) players.` +
				`<br/>Joined: <em class="${table.joinedPlayers >= table.playersCount.minPlayers ? 'enough-players' : 'not-enough-players'}">${table.joinedPlayers}</em> players.` +
				(table.currentGame ? ` <a href="#" class="game-link">See Game</a>` : ``) +
				(!table.currentGame && nameExists && !currentTable && table.joinedPlayers < table.playersCount.maxPlayers ? `<a href="#" class="join-link">Join</a>` : ``) +
				(!table.currentGame && currentTable === table.number ? ` <a href="#" class="leave-link">Leave</a>` : ``) +
				(!table.currentGame && table.joinedPlayers >= table.playersCount.minPlayers && currentTable === table.number ? ` <a href="#" class="start-link">Start</a>` : ``);
			container.insertBefore(li, newLi);
			let j = li.querySelector('a.join-link');
			j && j.addEventListener('click', async () => {
				let playerName = nameEl.value;
				if (playerName) {
					let location = await clientProxy.joinTable(table.number, playerName);
					if (location) {
						localStorage.setItem('tableNumber', table.number);
						localStorage.setItem('playerId', location.split('/').pop());
					}
				}
			});
			let l = li.querySelector('a.leave-link');
			l && l.addEventListener('click', async () => {
				await clientProxy.leaveTable(table.number, localStorage.getItem('playerId'));
				localStorage.removeItem('tableNumber');
				localStorage.removeItem('playerId');
			});
			let s = li.querySelector('a.start-link');
			s && s.addEventListener('click', async () => {
				let gameId = await clientProxy.startGame(table.number);
				if (gameId) {
					localStorage.setItem('gameId', gameId);
				}
			});
			let g = li.querySelector('a.game-link');
			g && g.addEventListener('click', async () => {
				let game = await clientProxy.gameOnTable(table.number);
				if (game) {
					localStorage.setItem('gameId', game.id);
					localStorage.setItem('tableNumber', table.number);
				}
			});
		});
		newLi.hidden = !nameExists || currentTable;
	}

	newLi.innerHTML =
		`<label><span>Min.players</span><input type="number" min="2" max="5" class="min-players" value="2" tabindex="101" /></label>` +
		`<label><span>Max.players</span><input type="number" min="2" max="5" class="max-players" value="5" tabindex="102"/></label>` +
		`<a href="#" class="new-table-link" tabindex="103">New table</a>`;
	container.appendChild(newLi);
	let n = newLi.querySelector('a.new-table-link');
	n && n.addEventListener('click', async () => {
		let minPlayers = parseInt(newLi.querySelector('.min-players').value);
		let maxPlayers = parseInt(newLi.querySelector('.max-players').value);
		let playerName = nameEl.value;
		if (playerName && minPlayers && maxPlayers && minPlayers <= maxPlayers) {
			let t = await clientProxy.newTable(minPlayers, maxPlayers);
			let tableNumber = t.split('/').pop();
			let location = await clientProxy.joinTable(tableNumber, playerName);
			localStorage.setItem('tableNumber', tableNumber);
			localStorage.setItem('playerId', location.split('/').pop());
		}
	});

	setInterval(fn, 1000);
	await fn();
}