import { customAlphabet } from "nanoid";
const nanoid = customAlphabet("0123456789abcdefghijklmnopqrstuvwxyz", 10);

export type Callback = (payload?: any) => void;

class RequestController {
  callbacks: { [requestId: string]: Callback } = {};

  request(callback: Callback): string {
    const requestId = nanoid();
    this.callbacks[requestId] = callback;
    return requestId;
  }

  response(requestId: string, payload: any): void {
    const callback = this.callbacks[requestId];
    if (!callback) return;
    callback(payload);
    delete this.callbacks[requestId];
  }
}

export default RequestController;
