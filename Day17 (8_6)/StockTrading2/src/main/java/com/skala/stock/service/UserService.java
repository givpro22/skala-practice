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

        return convertToDto(userRepository.save(user));
    }

    public UserDto getUserById(Long id) {
        return convertToDto(findUserOrThrow(id));
    }

    /** 전체 사용자를 조회한다. */
    public List<UserDto> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    /**
     * 사용자를 삭제한다.
     *
     * 포트폴리오나 거래 내역이 참조 중이면 삭제할 수 없다.
     * 특히 거래 내역은 "언제 무엇을 얼마에 샀다"는 기록이므로
     * 사용자를 지운다고 함께 없애지 않고 삭제를 거절한다.
     */
    @Transactional
    public void deleteUser(Long id) {
        User user = findUserOrThrow(id);

        if (portfolioRepository.existsByUserId(id)) {
            throw new ResourceInUseException("보유 중인 포트폴리오가 있어 삭제할 수 없습니다: " + user.getUsername());
        }
        if (transactionRepository.existsByUserId(id)) {
            throw new ResourceInUseException("거래 내역이 있어 삭제할 수 없습니다: " + user.getUsername());
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
