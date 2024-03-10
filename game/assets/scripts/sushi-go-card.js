const CardRoot = 'assets/images/cards/';
class SushiGoCard extends HTMLElement {
	constructor() {
		super();
		this.attachShadow({ mode: 'open' });
	}
	connectedCallback() {
		const template = document.createElement('template');
		template.innerHTML = `
			<style>
                      :host img {
                          width: 100%;
                          height: auto;
                          border-radius: 8px;
                          border: solid 1px #000;
					box-shadow: 2px 2px 3px 0 rgba(0,0,0,50%);
                      }
			</style>
			<div>
				<img />
			</div>
		`;
		this.shadowRoot.appendChild(template.content.cloneNode(true));
		const img = this.shadowRoot.querySelector('img');
		img.src = CardRoot + this.getAttribute('value') + '.png';
		img.alt = this.getAttribute('value');
	}
}
customElements.define('sushi-go-card', SushiGoCard);
