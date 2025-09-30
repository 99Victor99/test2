package service

import (
	"context"
	"fmt"

	"test2/api/users"
	"test2/internal/repository"
	"test2/pkg/logger"
)

// UserServiceInterface 用户服务接口
type UserServiceInterface interface {
	GetUser(ctx context.Context, uid int32) (*users.User, error)
	CreateUser(ctx context.Context, user *users.User) (*users.User, error)
	UpdateUser(ctx context.Context, user *users.User) (*users.User, error)
	DeleteUser(ctx context.Context, uid int32) error
	ListUsers(ctx context.Context, limit, offset int32) ([]*users.User, error)
}

// UserService 用户服务实现
type UserService struct {
	userRepo repository.UserRepositoryInterface
	logger   logger.Logger
}

// NewUserService 创建用户服务
func NewUserService(userRepo repository.UserRepositoryInterface, logger logger.Logger) UserServiceInterface {
	return &UserService{
		userRepo: userRepo,
		logger:   logger,
	}
}

// GetUser 获取用户
func (s *UserService) GetUser(ctx context.Context, uid int32) (*users.User, error) {
	s.logger.Info("Getting user", "uid", uid)

	user, err := s.userRepo.GetByID(ctx, uid)
	if err != nil {
		s.logger.Error("Failed to get user from repository", "uid", uid, "error", err)
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

// CreateUser 创建用户
func (s *UserService) CreateUser(ctx context.Context, user *users.User) (*users.User, error) {
	s.logger.Info("Creating user", "name", user.Name)

	// 业务逻辑验证
	if err := s.validateUser(user); err != nil {
		return nil, fmt.Errorf("user validation failed: %w", err)
	}

	// 检查用户是否已存在
	existingUser, err := s.userRepo.GetByName(ctx, user.Name)
	if err == nil && existingUser != nil {
		return nil, fmt.Errorf("user with name %s already exists", user.Name)
	}

	// 创建用户
	createdUser, err := s.userRepo.Create(ctx, user)
	if err != nil {
		s.logger.Error("Failed to create user in repository", "name", user.Name, "error", err)
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	s.logger.Info("User created successfully", "uid", createdUser.Uid, "name", createdUser.Name)
	return createdUser, nil
}

// UpdateUser 更新用户
func (s *UserService) UpdateUser(ctx context.Context, user *users.User) (*users.User, error) {
	s.logger.Info("Updating user", "uid", user.Uid)

	// 检查用户是否存在
	existingUser, err := s.userRepo.GetByID(ctx, user.Uid)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}
	if existingUser == nil {
		return nil, fmt.Errorf("user not found")
	}

	// 业务逻辑验证
	if err := s.validateUser(user); err != nil {
		return nil, fmt.Errorf("user validation failed: %w", err)
	}

	// 更新用户
	updatedUser, err := s.userRepo.Update(ctx, user)
	if err != nil {
		s.logger.Error("Failed to update user in repository", "uid", user.Uid, "error", err)
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	s.logger.Info("User updated successfully", "uid", updatedUser.Uid)
	return updatedUser, nil
}

// DeleteUser 删除用户
func (s *UserService) DeleteUser(ctx context.Context, uid int32) error {
	s.logger.Info("Deleting user", "uid", uid)

	err := s.userRepo.Delete(ctx, uid)
	if err != nil {
		s.logger.Error("Failed to delete user in repository", "uid", uid, "error", err)
		return fmt.Errorf("failed to delete user: %w", err)
	}

	s.logger.Info("User deleted successfully", "uid", uid)
	return nil
}

// ListUsers 获取用户列表
func (s *UserService) ListUsers(ctx context.Context, limit, offset int32) ([]*users.User, error) {
	s.logger.Info("Listing users", "limit", limit, "offset", offset)

	userList, err := s.userRepo.List(ctx, limit, offset)
	if err != nil {
		s.logger.Error("Failed to list users from repository", "error", err)
		return nil, fmt.Errorf("failed to list users: %w", err)
	}

	s.logger.Info("Users listed successfully", "count", len(userList))
	return userList, nil
}

// validateUser 验证用户数据
func (s *UserService) validateUser(user *users.User) error {
	if user.Name == "" {
		return fmt.Errorf("name is required")
	}
	if len(user.Name) > 100 {
		return fmt.Errorf("name too long")
	}
	if user.Age < 0 || user.Age > 150 {
		return fmt.Errorf("invalid age")
	}
	return nil
}
