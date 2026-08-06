package com.skala.stock.service;

import com.skala.stock.dto.UserDto;
import com.skala.stock.entity.User;
import com.skala.stock.exception.DuplicateResourceException;
import com.skala.stock.exception.ResourceInUseException;
import com.skala.stock.exception.ResourceNotFoundException;
import com.skala.stock.repository.PortfolioRepository;
import com.skala.stock.repository.TransactionRepository;
import com.skala.stock.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final PortfolioRepository portfolioRepository;
    private final TransactionRepository transactionRepository;

    @Transactional
    public UserDto createUser(UserDto userDto) {
        if (userRepository.existsByUsername(userDto.getUsername())) {
            throw new DuplicateResourceException("이미 존재하는 사용자명입니다: " + userDto.getUsername());
        }
        if (userRepository.existsByEmail(userDto.getEmail())) {
            throw new DuplicateResourceException("이미 존재하는 이메일입니다: " + userDto.getEmail());
        }

        User user = User.builder()
                .username(userDto.getUsername())
                .password(userDto.getPassword())
                .email(userDto.getEmail())
                .balance(userDto.getBalance())
                .build();

        User savedUser = userRepository.save(user);
        return convertToDto(savedUser);
    }

    public UserDto getUserById(Long id) {
        return convertToDto(findUserOrThrow(id));
    }

    public List<UserDto> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * 사용자 정보를 수정합니다.
     *
     * 사용자명과 이메일은 다른 사용자가 이미 쓰고 있으면 바꿀 수 없습니다.
     * (자기 자신이 쓰던 값을 그대로 보내는 것은 허용)
     */
    @Transactional
    public UserDto updateUser(Long id, UserDto userDto) {
        User user = findUserOrThrow(id);

        if (!user.getUsername().equals(userDto.getUsername())
                && userRepository.existsByUsername(userDto.getUsername())) {
            throw new DuplicateResourceException("이미 존재하는 사용자명입니다: " + userDto.getUsername());
        }
        if (!user.getEmail().equals(userDto.getEmail())
                && userRepository.existsByEmail(userDto.getEmail())) {
            throw new DuplicateResourceException("이미 존재하는 이메일입니다: " + userDto.getEmail());
        }

        user.setUsername(userDto.getUsername());
        user.setPassword(userDto.getPassword());
        user.setEmail(userDto.getEmail());
        user.setBalance(userDto.getBalance());

        return convertToDto(userRepository.save(user));
    }

    /**
     * 사용자를 삭제합니다.
     *
     * 포트폴리오나 거래 내역이 이 사용자를 참조하고 있으면 삭제할 수 없습니다.
     * 거래 기록은 보존되어야 하는 값이므로 함께 지우지 않고 거절합니다.
     */
    @Transactional
    public void deleteUser(Long id) {
        User user = findUserOrThrow(id);

        if (portfolioRepository.existsByUserId(id)) {
            throw new ResourceInUseException(
                    "보유 중인 포트폴리오가 있어 삭제할 수 없습니다: " + user.getUsername());
        }
        if (transactionRepository.existsByUserId(id)) {
            throw new ResourceInUseException(
                    "거래 내역이 있어 삭제할 수 없습니다: " + user.getUsername());
        }

        userRepository.delete(user);
    }

    private User findUserOrThrow(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("사용자", id));
    }

    private UserDto convertToDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .password(user.getPassword())
                .email(user.getEmail())
                .balance(user.getBalance())
                .build();
    }
}
