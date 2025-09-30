package main

import (
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"test2/api/users"
	"test2/internal/config"
	"test2/internal/handler"
	"test2/internal/repository"
	"test2/internal/service"
	"test2/pkg/logger"
)

func main() {
	// 初始化配置
	cfg := config.Load()

	// 初始化日志
	log := logger.New(cfg.LogLevel)

	// 初始化数据库连接
	// db := database.Connect(cfg.DatabaseURL)
	// defer db.Close()

	// 初始化仓储层
	userRepo := repository.NewUserRepository( /* db */ )

	// 初始化服务层
	userService := service.NewUserService(userRepo, log)

	// 初始化处理层
	userHandler := handler.NewUserHandler(userService, log)

	// 创建 gRPC 服务器
	server := grpc.NewServer()

	// 注册服务
	users.RegisterUsersServiceServer(server, userHandler)

	// 启用反射（开发环境）
	if cfg.Environment == "development" {
		reflection.Register(server)
	}

	// 启动服务器
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.Port))
	if err != nil {
		log.Fatal("Failed to listen", "error", err)
	}

	// 优雅关闭
	go func() {
		log.Info("Starting gRPC server", "port", cfg.Port)
		if err := server.Serve(lis); err != nil {
			log.Fatal("Failed to serve", "error", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...")
	server.GracefulStop()
	log.Info("Server stopped")
}
