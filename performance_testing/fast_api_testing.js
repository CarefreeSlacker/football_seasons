import http from "k6/http"
import { getEnvironmentHost, getEnvironmentPort, sendRequest } from './utils/request.js'

const host = getEnvironmentHost();
const port = getEnvironmentPort();

export default function() {
    sendRequest(host, port, '/api/seasons');
    return true;
}
