import express, { Request, Response } from "express";
import { eventService } from "../services/events/event-service.js";
import { stellarPaywall } from "../middleware/stellar-paywall.js";
import { EventSearchParams } from "../services/events/types.js";

const router = express.Router();

const RECIPIENT_ADDRESS =
  process.env.SERVICE_OPERATOR_PUBLIC ||
  "GDKU2DY4TTRRSQ6BBFYTDV2GEWREHCIDUM5FFXLIF66PDOO3HYJ2YZIF";
const USDC_CONTRACT =
  "CBIELTK6YBZJU5UP2WWQEUCYKLPU6AUNZ2BQ4WWFEIE3USCIHMXQDAMA";
const SOROBAN_RPC_URL =
  process.env.SOROBAN_RPC_URL || "https://soroban-testnet.stellar.org";

const paywallMiddleware = stellarPaywall({
  priceStroops: 50000, // 0.005 USDC
  recipientAddress: RECIPIENT_ADDRESS,
  usdcContractId: USDC_CONTRACT,
  rpcUrl: SOROBAN_RPC_URL,
});

// GET /search - Paid
router.get(
  "/search",
  paywallMiddleware,
  async (req: Request, res: Response) => {
    try {
      const getS = (key: string): string | undefined => {
        const val = (req.query as any)[key];
        if (!val) return undefined;
        if (Array.isArray(val)) return String(val[0]);
        return String(val);
      };

      const params: EventSearchParams = {
        q: getS("q"),
        city: getS("city"),
        country: getS("country"),
        lat: getS("lat") ? parseFloat(getS("lat")!) : undefined,
        lng: getS("lng") ? parseFloat(getS("lng")!) : undefined,
        radius: getS("radius") ? parseFloat(getS("radius")!) : undefined,
        category: getS("category") as any,
        dateFrom: getS("dateFrom"),
        dateTo: getS("dateTo"),
        platform: getS("platform"),
        minPrice: getS("minPrice") ? parseFloat(getS("minPrice")!) : undefined,
        maxPrice: getS("maxPrice") ? parseFloat(getS("maxPrice")!) : undefined,
        isFree:
          getS("isFree") === "true"
            ? true
            : getS("isFree") === "false"
              ? false
              : undefined,
        page: getS("page") ? parseInt(getS("page")!) : undefined,
        limit: getS("limit") ? parseInt(getS("limit")!) : undefined,
      };

      const result = await eventService.search(params);
      res.json(result);
    } catch (error) {
      console.error("[Events API] Search error:", error);
      res.status(500).json({ error: "Internal server error during search" });
    }
  },
);

// GET /events/:platform/:id - Paid
router.get(
  "/events/:platform/:id",
  paywallMiddleware,
  async (req: Request, res: Response) => {
    try {
      const platform = String(req.params.platform);
      const id = String(req.params.id);
      const result = await eventService.getEventById(platform, id);
      if (!result) {
        return res.status(404).json({ error: "Event not found" });
      }
      res.json(result);
    } catch (error) {
      res.status(500).json({ error: "Internal server error fetching event" });
    }
  },
);

// GET /platforms - Free
router.get("/platforms", (req: Request, res: Response) => {
  res.json(eventService.getSupportedPlatforms());
});

// GET /countries - Free
router.get("/countries", (req: Request, res: Response) => {
  res.json(eventService.getAvailableCountries());
});

// GET /categories - Free
router.get("/categories", (req: Request, res: Response) => {
  const categories = [
    { id: "music", name: "Music", emoji: "🎵" },
    { id: "sports", name: "Sports", emoji: "🏆" },
    { id: "arts", name: "Arts & Theatre", emoji: "🎨" },
    { id: "comedy", name: "Comedy", emoji: "😂" },
    { id: "conference", name: "Conference", emoji: "💼" },
    { id: "festival", name: "Festival", emoji: "🎪" },
    { id: "theatre", name: "Theatre", emoji: "🎭" },
    { id: "nightlife", name: "Nightlife", emoji: "🌃" },
    { id: "family", name: "Family", emoji: "👨‍👩‍👧‍👦" },
    { id: "other", name: "Other", emoji: "✨" },
  ];
  res.json(categories);
});

export default router;
