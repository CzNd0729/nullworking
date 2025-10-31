package com.nullworking.model.dto;

import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
public class ItemOrderAdjustRequest {

    @Schema(description = "事项ID列表，按新的显示顺序排列", example = "[2,3,5,1,7,8,10,9,4,6]")
    private List<Integer> displayOrders;
}
