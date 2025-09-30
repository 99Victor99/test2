package middleware

import (
	"context"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"test2/pkg/logger"
)

// LoggingInterceptor gRPC 日志中间件
func LoggingInterceptor(logger logger.Logger) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (interface{}, error) {
		start := time.Now()

		// 记录请求开始
		logger.Info("gRPC request started",
			"method", info.FullMethod,
			"request", req,
		)

		// 执行处理器
		resp, err := handler(ctx, req)

		// 计算耗时
		duration := time.Since(start)

		// 记录请求结束
		if err != nil {
			st, _ := status.FromError(err)
			logger.Error("gRPC request failed",
				"method", info.FullMethod,
				"duration", duration,
				"code", st.Code(),
				"message", st.Message(),
			)
		} else {
			logger.Info("gRPC request completed",
				"method", info.FullMethod,
				"duration", duration,
			)
		}

		return resp, err
	}
}

// RecoveryInterceptor gRPC 恢复中间件
func RecoveryInterceptor(logger logger.Logger) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (resp interface{}, err error) {
		defer func() {
			if r := recover(); r != nil {
				logger.Error("gRPC panic recovered",
					"method", info.FullMethod,
					"panic", r,
				)
				err = status.Error(codes.Internal, "internal server error")
			}
		}()

		return handler(ctx, req)
	}
}
