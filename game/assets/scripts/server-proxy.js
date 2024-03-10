class ServerProxy {
	/**
	 * @param {string} apiEndpoint
	 * @param {string} webEndpoint
	 * @param {string} token
	 * @param {function} errorHandler
	 */
	constructor(apiEndpoint, webEndpoint, token, errorHandler) {
		this.apiEndpoint = apiEndpoint;
		this.webEndpoint = webEndpoint;
		this.token = token;
		this.errorHandler = errorHandler;
	}

	/**
	 * @param {string} url
	 */
	async webCall(url) {
		document.body.classList.add('loading');
		let response = await fetch(this.webEndpoint + url);
		document.body.classList.remove('loading');
		if (response.status === 200) {
			return await response.text();
		}
		let result = await response.json();
		this.errorHandler(result.error || result.message);
	}

	/**
	 * @param {string} url
	 * @param {"GET"|"POST"|"PUT"|"PATCH"|"DELETE"} method
	 * @param {string|null} body
	 * @param {Array<number>} expectedStatusCodes
	 */
	async apiCall(url, method, body, expectedStatusCodes) {
		document.body.classList.add('loading');
		try {
			let response = await fetch(this.apiEndpoint + url, {
				method: method, body: body, headers: {
					"content-type": "application/json",
					"X-Token": this.token
				}
			});
			document.body.classList.remove('loading');
			if (expectedStatusCodes.indexOf(response.status) === -1) {
				let result = await response.json();
				this.errorHandler(result.error || result.message);
				return;
			}
			return {
				status: response.status,
				location: response.headers.get('Location'),
				response: response,
				json: response.headers.get('Content-Type') === 'application/json' ? await response.json() : null
			};
		} catch (e) {
			document.body.classList.remove('loading');
			throw e;
		}
	}
}

export default ServerProxy;