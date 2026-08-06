package com.skala.stock.controller;

import com.skala.stock.dto.UserDto;
import com.skala.stock.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Validated // @PathVariable 에 붙인 @Min 을 동작시키기 위해 필요
@Tag(name = "사용자 관리", description = "사용자 CRUD API")
public class UserController {

    private final UserService userService;

    @PostMapping
    @Operation(summary = "사용자 생성", description = "새로운 사용자를 등록합니다")
    public ResponseEntity<UserDto> createUser(@Valid @RequestBody UserDto userDto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.createUser(userDto));
    }

    @GetMapping("/{id}")
    @Operation(summary = "사용자 조회", description = "ID로 사용자를 조회합니다")
    public ResponseEntity<UserDto> getUserById(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "ID는 1 이상이어야 합니다") Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @GetMapping
    @Operation(summary = "전체 사용자 조회", description = "모든 사용자를 조회합니다")
    public ResponseEntity<List<UserDto>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "사용자 삭제",
            description = "ID로 사용자를 삭제합니다. 포트폴리오·거래 내역이 있으면 삭제할 수 없습니다(409)")
    public ResponseEntity<Void> deleteUser(
            @Parameter(description = "사용자 ID", example = "1")
            @PathVariable @Min(value = 1, message = "ID는 1 이상이어야 합니다") Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
