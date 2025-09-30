package handler

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"test2/api/users"
	"test2/internal/service"
	"test2/pkg/logger"
)

// UserHandler 用户处理器
type UserHandler struct {
	users.UnimplementedUsersServiceServer
	userService service.UserServiceInterface
	logger      logger.Logger
}

// NewUserHandler 创建用户处理器
func NewUserHandler(userService service.UserServiceInterface, logger logger.Logger) *UserHandler {
	return &UserHandler{
		userService: userService,
		logger:      logger,
	}
}

// Get 获取用户信息
func (h *UserHandler) Get(ctx context.Context, req *users.User) (*users.User, error) {
	h.logger.Info("Get user request", "uid", req.Uid)

	// 参数验证
	if req.Uid <= 0 {
		return nil, status.Error(codes.InvalidArgument, "invalid user id")
	}

	// 调用服务层
	user, err := h.userService.GetUser(ctx, req.Uid)
	if err != nil {
		h.logger.Error("Failed to get user", "uid", req.Uid, "error", err)
		return nil, status.Error(codes.Internal, "failed to get user")
	}

	if user == nil {
		return nil, status.Error(codes.NotFound, "user not found")
	}

	h.logger.Info("Get user success", "uid", req.Uid)
	return user, nil
}

// CreateUser 创建用户
func (h *UserHandler) CreateUser(ctx context.Context, req *users.User) (*users.User, error) {
	h.logger.Info("Create user request", "name", req.Name)

	// 参数验证
	if req.Name == "" {
		return nil, status.Error(codes.InvalidArgument, "name is required")
	}

	// 调用服务层
	user, err := h.userService.CreateUser(ctx, req)
	if err != nil {
		h.logger.Error("Failed to create user", "name", req.Name, "error", err)
		return nil, status.Error(codes.Internal, "failed to create user")
	}

	h.logger.Info("Create user success", "uid", user.Uid, "name", user.Name)
	return user, nil
}

// UpdateUser 更新用户
func (h *UserHandler) UpdateUser(ctx context.Context, req *users.User) (*users.User, error) {
	h.logger.Info("Update user request", "uid", req.Uid)

	// 参数验证
	if req.Uid <= 0 {
		return nil, status.Error(codes.InvalidArgument, "invalid user id")
	}

	// 调用服务层
	user, err := h.userService.UpdateUser(ctx, req)
	if err != nil {
		h.logger.Error("Failed to update user", "uid", req.Uid, "error", err)
		return nil, status.Error(codes.Internal, "failed to update user")
	}

	h.logger.Info("Update user success", "uid", user.Uid)
	return user, nil
}
