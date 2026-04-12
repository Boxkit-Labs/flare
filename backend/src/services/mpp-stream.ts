import { WebSocketServer, WebSocket } from "ws";
import { Server } from "http";
import { mppChannelManager } from "./mpp-channel-manager.js";
import { v4 as uuidv4 } from "uuid";
import { getWatcherById } from "../db/queries.js";

interface StreamClient {
  ws: WebSocket;
  userId: string;
  watcherId: string;
  serviceId: string;
  channelId: string;
  lastProofAt: number;
  cumulativeCost: number;
  intervalId?: NodeJS.Timeout;
  paymentTimeoutId?: NodeJS.Timeout;
}

export class MPPStreamService {
  private wss: WebSocketServer;
  private clients = new Map<string, StreamClient>();
  private readonly FRAME_COST_USDC = 0.0005;

  constructor(options?: { server?: Server; port?: number }) {
    if (options?.server) {
      this.wss = new WebSocketServer({
        server: options.server,
        path: "/ws/stream",
      });
      console.log(
        `[MPP Stream] WebSocket server attached to HTTP server at /ws/stream`,
      );
    } else {
      const port = options?.port || 3000;
      this.wss = new WebSocketServer({
        port,
        host: "0.0.0.0",
        path: "/ws/stream",
      });
      console.log(
        `[MPP Stream] WebSocket server started on port ${port} at 0.0.0.0/ws/stream`,
      );
    }

    this.wss.on("connection", async (ws: WebSocket, req: any) => {
      console.log(`[MPP Stream] New connection attempt: ${req.url}`);

      try {
        const url = new URL(req.url, `ws://${req.headers.host}`);
        const userId = url.searchParams.get("userId");
        const watcherId = url.searchParams.get("watcherId");

        let serviceId = url.searchParams.get("serviceId");
        let channelId = url.searchParams.get("channelId");

        if (!userId || !watcherId) {
          ws.send(
            JSON.stringify({
              error: "Missing required parameters (userId, watcherId)",
            }),
          );
          ws.close(1008);
          return;
        }

        const watcher = await getWatcherById(watcherId);
        if (!watcher || watcher.user_id !== userId) {
          ws.send(
            JSON.stringify({ error: "Watcher not found or unauthorized" }),
          );
          ws.close(1008);
          return;
        }

        if (!serviceId) serviceId = `${watcher.type}-service`;

        const channelState = await mppChannelManager.getChannelStatus(
          userId,
          serviceId,
        );
        if (!channelState || channelState.status !== "open") {
          ws.send(
            JSON.stringify({
              error: "Valid open channel not found for this service",
            }),
          );
          ws.close(1008);
          return;
        }

        if (!channelId) channelId = channelState.channelId;

        if (channelId !== channelState.channelId) {
          ws.send(
            JSON.stringify({
              error: "Mismatch between provided and active channelId",
            }),
          );
          ws.close(1008);
          return;
        }

        const clientId = uuidv4();
        const client: StreamClient = {
          ws,
          userId,
          watcherId,
          serviceId,
          channelId,
          lastProofAt: Date.now(),
          cumulativeCost: 0,
        };

        this.clients.set(clientId, client);
        console.log(`[MPP Stream] Client connected: ${clientId}`);

        client.intervalId = setInterval(
          () => this.sendDataFrame(clientId),
          10000,
        );

        ws.on("message", async (message: string) => {
          await this.handleMessage(clientId, message);
        });

        ws.on("close", () => {
          this.handleDisconnect(clientId);
        });
      } catch (err: any) {
        console.error(`[MPP Stream] Connection error:`, err);
        ws.send(JSON.stringify({ error: "Internal server error" }));
        ws.close(1011);
      }
    });
  }

  private sendDataFrame(clientId: string) {
    const client = this.clients.get(clientId);
    if (!client) return;

    client.cumulativeCost += this.FRAME_COST_USDC;

    const isFinancial = client.serviceId.includes('crypto') || client.serviceId.includes('stock');
    const mockPrice = isFinancial ? (50000 + (Math.random() * 1000) - 500) : null;

    const dataFrame = {
      type: "data",
      service: client.serviceId,
      payload: {
        timestamp: new Date().toISOString(),
        status: "active",
        price: mockPrice,
        data: isFinancial 
          ? `Live ${client.serviceId} update: $${mockPrice?.toFixed(2)}`
          : `Mock data for ${client.serviceId} at ${Date.now()}`,
      },
      cost_this_frame: this.FRAME_COST_USDC.toString(),
      total_session_cost: client.cumulativeCost.toFixed(4),
    };

    client.ws.send(JSON.stringify(dataFrame));

    if (Date.now() - client.lastProofAt > 60000) {
      this.requestPaymentProof(clientId);
    }
  }

  private requestPaymentProof(clientId: string) {
    const client = this.clients.get(clientId);
    if (!client) return;

    if (client.paymentTimeoutId) clearTimeout(client.paymentTimeoutId);

    const amountDue = client.cumulativeCost;

    const paymentFrame = {
      type: "payment_required",
      amount_due: amountDue.toFixed(4),
      cumulative_amount: amountDue.toFixed(4),
      deadline_seconds: 10,
    };

    client.ws.send(JSON.stringify(paymentFrame));

    client.paymentTimeoutId = setTimeout(() => {
      console.warn(
        `[MPP Stream] Client ${clientId} failed to provide payment proof. Disconnecting.`,
      );
      client.ws.send(
        JSON.stringify({ type: "error", message: "Payment proof timeout" }),
      );
      client.ws.close(1008);
      this.handleDisconnect(clientId);
    }, 10000);
  }

  private async handleMessage(clientId: string, messageStr: string) {
    const client = this.clients.get(clientId);
    if (!client) return;

    try {
      const message = JSON.parse(messageStr);
      if (message.type === "payment_proof" && message.proof) {
        if (client.paymentTimeoutId) {
          clearTimeout(client.paymentTimeoutId);
          client.paymentTimeoutId = undefined;
        }

        const amountStroops = Math.round(client.cumulativeCost * 10_000_000);
        const isValid = await mppChannelManager.verifyPaymentProof(
          client.channelId,
          JSON.stringify(message.proof),
          amountStroops,
        );

        if (isValid) {
          client.lastProofAt = Date.now();
          client.ws.send(
            JSON.stringify({ type: "payment_ack", message: "Proof accepted" }),
          );
        } else {
          client.ws.send(
            JSON.stringify({ type: "error", message: "Invalid payment proof" }),
          );
          client.ws.close(1008);
          this.handleDisconnect(clientId);
        }
      }
    } catch (e) {
      console.error(`[MPP Stream] Error parsing message from ${clientId}:`, e);
    }
  }

  private handleDisconnect(clientId: string) {
    const client = this.clients.get(clientId);
    if (client) {
      if (client.intervalId) clearInterval(client.intervalId);
      if (client.paymentTimeoutId) clearTimeout(client.paymentTimeoutId);
      console.log(
        `[MPP Stream] Client disconnected: ${clientId}. Total Cost: ${client.cumulativeCost}`,
      );
      this.clients.delete(clientId);
    }
  }
}
