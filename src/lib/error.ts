import { Request, Response, NextFunction } from "express";

export function notFound(_req: Request, res: Response) {
  res.status(404).json({ error: { code: "NOT_FOUND", message: "Route not found" } });
}

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  const status = err.status ?? 500;
  const message = err.message ?? "Internal Server Error";
  const code = err.code ?? (status === 500 ? "INTERNAL_ERROR" : "BAD_REQUEST");

  res.status(status).json({ error: { code, message } });
}
