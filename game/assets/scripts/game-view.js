import clientProxy from './boot.js';

export default async function (container) {
	let lastGameValue = '';

	let showRound = (players, round, el, r) => {
		el.innerHTML = `<h3>Round ${r} / 3</h3>`;
		let playerCardsEl = document.createElement('div');
		playerCardsEl.className = 'player-cards';
		players.forEach(playerName => {
			let playerEl = document.createElement('div');
			playerEl.className = 'player other-player-cards';
			let titleEl = document.createElement('h4');
			titleEl.innerHTML = playerName;
			playerEl.appendChild(titleEl);
			let cardsEl = document.createElement('div');
			cardsEl.className = 'cards';
			let cards = (round?.cards && round.cards[playerName]) ?? round?.openCards[playerName] ?? [];
			cards.forEach(card => {
				let cardEl = document.createElement('sushi-go-card');
				cardEl.setAttribute('value', card);
				cardsEl.appendChild(cardEl);
			});
			playerEl.appendChild(cardsEl);
			playerCardsEl.appendChild(playerEl);
		});
		el.appendChild(playerCardsEl);
	};

	let fn = async () => {
		let gameId = localStorage.getItem('gameId');
		container.hidden = !gameId;
		if (!gameId) {
			return;
		}

		let playerId = localStorage.getItem('playerId');

		let checkGameOver = game => {
			if (game.completedRounds.length === 3) {
				infoEl.innerHTML = `<h2>Game Over</h2>`;
				if (playerId) {
					let ownCards = container.querySelector(`#own-cards`);
					if (ownCards) {
						ownCards.hidden = true;
					}
					backToTablesEl.hidden = false;
				}
			} else {
				let tableNumber = localStorage.getItem('tableNumber');
				infoEl.innerHTML = `<h2>${tableNumber ? `Table #${tableNumber} / ` : ``}Current round: ${game.completedRounds.length + 1} / 3</h2>`;
			}
		};

		let loopCompleted = (game, showActive) => {
			let r = 0;
			let players = game.players;
			let tableNumber = game.tableNumber;
			let crFn = round => {
				let elId = `round-${r}`;
				let el = container.querySelector(`#${elId}`);
				if (!el) {
					el = document.createElement('div');
					el.id = elId;
					el.className = 'game-round';
					roundsEl.appendChild(el);
				}
				el.hidden = false;
				r++;
				showRound(players, round, el, r);
			};
			game.completedRounds.forEach(crFn);
			if (showActive) {
				let elId = `round-${r}`;
				let el = container.querySelector(`#${elId}`);
				if (!el) {
					el = document.createElement('div');
					el.id = elId;
					el.className = 'game-round';
					roundsEl.appendChild(el);
				}
				el.hidden = false;
				r++;
				if (showActive === true) {
					showRound(players, game.activeRound, el, r);
				} else {
					let playerName = showActive;
					let playersWithoutCurrent = players.filter(p => p !== playerName);
					showRound(playersWithoutCurrent, game.playerActiveRound, el, r, playerName);
				}
			}
		};
		for(var r = 1; r <= 3; r++) {
			let elId = `round-${r}`;
			let el = container.querySelector(`#${elId}`);
			if (el) {
				el.hidden = true;
			}
		}

		if (playerId) {
			let game = await clientProxy.playerGame(gameId, playerId);
			if (!game) {
				return;
			}
			let newGameValue = JSON.stringify(game);
			if (newGameValue === lastGameValue) {
				return;
			}
			lastGameValue = newGameValue;

			checkGameOver(game);
			backToTablesEl.hidden = game.completedRounds.length !== 3;
			let playerName = localStorage.getItem('name') || '';
			loopCompleted(game, game.completedRounds.length !== 3 ? playerName : false);

			if (game.playerActiveRound) {
				let elId = `own-cards`;
				let el = container.querySelector(`#${elId}`);
				if (!el) {
					el = document.createElement('div');
					el.id = elId;
					el.className = 'player own-cards';
					el.innerHTML = `<h4>${playerName}<a href="#" class="play-move-link">Play</a></h4><div class="cards played-cards"></div><h5>Select your next card:</h5><div class="cards active-cards"></div>`;
					roundsEl.appendChild(el);
					let playMoveLink = el.querySelector('.play-move-link');
					playMoveLink.addEventListener('click', async e => {
						e.preventDefault();
						let chosenCard = activeCardsEl.querySelectorAll('.selected');
						let chopsticksCard = playedCardsEl.querySelector('.selected');
						//if ((chopsticksCard && chosenCard.length === 2) || (!chopsticksCard && chosenCard.length === 1)) {
						if (chopsticksCard && chosenCard.length === 2) {
							await clientProxy.playMove(gameId, playerId,
								chosenCard[0].getAttribute('value'), chosenCard[1].getAttribute('value'));
							playMoveLink.classList.add('played');
						} else if (!chopsticksCard && chosenCard.length === 1) {
							await clientProxy.playMove(gameId, playerId,
								chosenCard[0].getAttribute('value'), null);
							playMoveLink.classList.add('played');
						}
					});
				} else {
					let playMoveLink = el.querySelector('.play-move-link');
					playMoveLink.classList.remove('played');
				}

				let playedCardsEl = el.querySelector('.played-cards');
				let activeCardsEl = el.querySelector('.active-cards');

				let checkPlayState = () => {

					let playMoveLink = el.querySelector('.play-move-link');
					let chosenCard = activeCardsEl.querySelectorAll('.selected');
					let chopsticksCard = playedCardsEl.querySelector('.selected');
					if (playMoveLink) {
						playMoveLink.hidden = !((chopsticksCard && chosenCard.length === 2) || (!chopsticksCard && chosenCard.length === 1));
					}
				};

				checkPlayState();

				playedCardsEl.innerHTML = '';
				activeCardsEl.innerHTML = '';

				game.playerActiveRound.openCards[playerName].forEach(card => {
					let cardEl = document.createElement('sushi-go-card');
					cardEl.setAttribute('value', card);
					if (card === 'chopsticks') {
						cardEl.addEventListener('click', e => {
							cardEl.classList.toggle('selected');
							checkPlayState();
						});
					}
					playedCardsEl.appendChild(cardEl);
				});
				game.playerActiveRound.playerHiddenCards.forEach(card => {
					let cardEl = document.createElement('sushi-go-card');
					cardEl.setAttribute('value', card);
					cardEl.addEventListener('click', e => {
						cardEl.classList.toggle('selected');
						checkPlayState();
					});
					activeCardsEl.appendChild(cardEl);
				});
			}
		} else {
			let game = await clientProxy.game(gameId);
			if (!game) {
				return;
			}
			let newGameValue = JSON.stringify(game);
			if (newGameValue === lastGameValue) {
				return;
			}
			lastGameValue = newGameValue;

			checkGameOver(game);
			backToTablesEl.hidden = false;
			loopCompleted(game, true);
		}
	}

	let headingEl = document.createElement('div');
	headingEl.className = 'heading';

	let infoEl = document.createElement('div');
	infoEl.className = 'info';

	headingEl.appendChild(infoEl);
	let backToTablesEl = document.createElement('a');
	backToTablesEl.href = '#';
	backToTablesEl.hidden = true;
	backToTablesEl.innerHTML = 'Back to Tables';
	backToTablesEl.className = 'back-to-tables-link';
	backToTablesEl.addEventListener('click', e => {
		e.preventDefault();
		localStorage.removeItem('gameId');
	});
	headingEl.appendChild(backToTablesEl);

	container.appendChild(headingEl);

	let roundsEl = document.createElement('div');
	roundsEl.className = 'rounds';
	container.appendChild(roundsEl);

	setInterval(fn, 1000);
	await fn();
}