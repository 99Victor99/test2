package repository

import (
	"context"
	"fmt"
	"sync"

	"test2/api/users"
)

// UserRepositoryInterface 用户仓储接口
type UserRepositoryInterface interface {
	GetByID(ctx context.Context, uid int32) (*users.User, error)
	GetByName(ctx context.Context, name string) (*users.User, error)
	Create(ctx context.Context, user *users.User) (*users.User, error)
	Update(ctx context.Context, user *users.User) (*users.User, error)
	Delete(ctx context.Context, uid int32) error
	List(ctx context.Context, limit, offset int32) ([]*users.User, error)
}

// UserRepository 用户仓储实现（内存版本，实际项目中应该使用数据库）
type UserRepository struct {
	mu     sync.RWMutex
	users  map[int32]*users.User
	nextID int32
}

// NewUserRepository 创建用户仓储
func NewUserRepository( /* db *database.DB */ ) UserRepositoryInterface {
	return &UserRepository{
		users:  make(map[int32]*users.User),
		nextID: 1,
	}
}

// GetByID 根据ID获取用户
func (r *UserRepository) GetByID(ctx context.Context, uid int32) (*users.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	user, exists := r.users[uid]
	if !exists {
		return nil, nil // 用户不存在
	}

	// 返回副本，避免外部修改
	return &users.User{
		Uid:  user.Uid,
		Name: user.Name,
		Age:  user.Age,
	}, nil
}

// GetByName 根据名称获取用户
func (r *UserRepository) GetByName(ctx context.Context, name string) (*users.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, user := range r.users {
		if user.Name == name {
			return &users.User{
				Uid:  user.Uid,
				Name: user.Name,
				Age:  user.Age,
			}, nil
		}
	}

	return nil, nil // 用户不存在
}

// Create 创建用户
func (r *UserRepository) Create(ctx context.Context, user *users.User) (*users.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	// 分配新的ID
	user.Uid = r.nextID
	r.nextID++

	// 存储用户
	r.users[user.Uid] = &users.User{
		Uid:  user.Uid,
		Name: user.Name,
		Age:  user.Age,
	}

	// 返回创建的用户
	return &users.User{
		Uid:  user.Uid,
		Name: user.Name,
		Age:  user.Age,
	}, nil
}

// Update 更新用户
func (r *UserRepository) Update(ctx context.Context, user *users.User) (*users.User, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	// 检查用户是否存在
	if _, exists := r.users[user.Uid]; !exists {
		return nil, fmt.Errorf("user not found")
	}

	// 更新用户
	r.users[user.Uid] = &users.User{
		Uid:  user.Uid,
		Name: user.Name,
		Age:  user.Age,
	}

	// 返回更新的用户
	return &users.User{
		Uid:  user.Uid,
		Name: user.Name,
		Age:  user.Age,
	}, nil
}

// Delete 删除用户
func (r *UserRepository) Delete(ctx context.Context, uid int32) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// 检查用户是否存在
	if _, exists := r.users[uid]; !exists {
		return fmt.Errorf("user not found")
	}

	// 删除用户
	delete(r.users, uid)
	return nil
}

// List 获取用户列表
func (r *UserRepository) List(ctx context.Context, limit, offset int32) ([]*users.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var userList []*users.User
	var count int32

	for _, user := range r.users {
		// 跳过 offset 数量的记录
		if count < offset {
			count++
			continue
		}

		// 达到 limit 数量后停止
		if int32(len(userList)) >= limit {
			break
		}

		userList = append(userList, &users.User{
			Uid:  user.Uid,
			Name: user.Name,
			Age:  user.Age,
		})
	}

	return userList, nil
}

// 实际项目中的数据库实现示例：
/*
// PostgreSQL 实现
func (r *UserRepository) GetByID(ctx context.Context, uid int32) (*users.User, error) {
	query := `SELECT uid, name, age FROM users WHERE uid = $1`

	var user users.User
	err := r.db.QueryRowContext(ctx, query, uid).Scan(&user.Uid, &user.Name, &user.Age)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

func (r *UserRepository) Create(ctx context.Context, user *users.User) (*users.User, error) {
	query := `INSERT INTO users (name, age) VALUES ($1, $2) RETURNING uid`

	err := r.db.QueryRowContext(ctx, query, user.Name, user.Age).Scan(&user.Uid)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}
*/
