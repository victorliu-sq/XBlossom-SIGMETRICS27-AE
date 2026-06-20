#ifndef X_BLOSSOM_CACHE_FLUSHER_H
#define X_BLOSSOM_CACHE_FLUSHER_H

#pragma once
#include <vector>
#include <cstdint>
#include <cstddef>

class CacheFlusher {
public:
    // Allocate SIZE_BYTES of contiguous memory
    explicit CacheFlusher(size_t size_bytes)
        : data_(size_bytes) {}

    // Flush all CPU caches by sequentially touching each cache line
    void flush() {
        // Touch one byte per cache line (64 bytes)
        constexpr size_t CACHE_LINE = 64;

        volatile uint8_t sink = 0;
        for (size_t i = 0; i < data_.size(); i += CACHE_LINE) {
            sink ^= data_[i];
        }
        sink_ = sink; // prevent optimization
    }

private:
    std::vector<int8_t> data_;
    volatile uint8_t sink_ = 0;
};

#endif //X_BLOSSOM_CACHE_FLUSHER_H