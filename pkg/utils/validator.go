package utils

import (
	"fmt"
	"regexp"
	"strings"
)

// ValidateEmail 验证邮箱格式
func ValidateEmail(email string) error {
	if email == "" {
		return fmt.Errorf("email is required")
	}

	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return fmt.Errorf("invalid email format")
	}

	return nil
}

// ValidateUsername 验证用户名
func ValidateUsername(username string) error {
	if username == "" {
		return fmt.Errorf("username is required")
	}

	if len(username) < 3 || len(username) > 50 {
		return fmt.Errorf("username must be between 3 and 50 characters")
	}

	// 只允许字母、数字、下划线
	usernameRegex := regexp.MustCompile(`^[a-zA-Z0-9_]+$`)
	if !usernameRegex.MatchString(username) {
		return fmt.Errorf("username can only contain letters, numbers, and underscores")
	}

	return nil
}

// ValidateAge 验证年龄
func ValidateAge(age int32) error {
	if age < 0 || age > 150 {
		return fmt.Errorf("age must be between 0 and 150")
	}
	return nil
}

// SanitizeString 清理字符串
func SanitizeString(s string) string {
	// 移除前后空格
	s = strings.TrimSpace(s)

	// 移除多余的空格
	spaceRegex := regexp.MustCompile(`\s+`)
	s = spaceRegex.ReplaceAllString(s, " ")

	return s
}
