import ServerProxy from './server-proxy.js' ;
import Client from './client.js';

const cookieMatch = document.cookie.match(/x-token=(.*?)$/);
const token = cookieMatch && cookieMatch[1] || '';

// noinspection JSFileReferences
import { apiEndpoint, webEndpoint } from './env.js';

export default new Client(
	new ServerProxy(
		apiEndpoint,
		webEndpoint,
		token,
		errorMessage => document.querySelector('#current-error').innerHTML = errorMessage
	)
);
