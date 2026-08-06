import { Controller, Get, ServiceUnavailableException } from "@nestjs/common";
import { PrismaService } from "./prisma/prisma.service";
import { RedisService } from "./redis/redis.module";

@Controller("health")
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Get()
  health() {
    return {
      status: "ok",
      service: "resilia-api-gateway",
      region: process.env.DEPLOY_REGION || "A",
      version: process.env.APP_VERSION || "0.1.0",
      timestamp: new Date().toISOString(),
    };
  }

  @Get("live")
  live() {
    return { status: "alive" };
  }

  @Get("ready")
  async ready() {
    const checks: Record<string, string> = {
      database: "unknown",
      redis: "unknown",
    };

    try {
      await this.prisma.$queryRaw`SELECT 1`;
      checks.database = "up";
    } catch {
      checks.database = "down";
    }

    if (this.redis.usingMemory) {
      checks.redis = process.env.REDIS_URL ? "degraded" : "memory";
    } else {
      try {
        const pong = await this.redis.get("__health_probe__");
        void pong;
        checks.redis = "up";
      } catch {
        checks.redis = "down";
      }
    }

    const ok = checks.database === "up";
    const body = {
      status: ok ? "ready" : "not_ready",
      checks,
      timestamp: new Date().toISOString(),
    };

    if (!ok) throw new ServiceUnavailableException(body);
    return body;
  }
}
