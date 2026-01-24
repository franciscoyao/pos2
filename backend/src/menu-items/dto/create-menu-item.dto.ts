import { IsString, IsNumber, IsOptional, IsBoolean, IsIn } from 'class-validator';

export class CreateMenuItemDto {
    @IsString()
    @IsOptional()
    code?: string;

    @IsString()
    name: string;

    @IsNumber()
    price: number;

    @IsNumber()
    categoryId: number;

    @IsString()
    @IsOptional()
    station?: string;

    @IsString()
    @IsOptional()
    @IsIn(['dine-in', 'takeaway'])
    type?: string;

    @IsString()
    @IsOptional()
    status?: string;

    @IsBoolean()
    @IsOptional()
    allowPriceEdit?: boolean;
}
