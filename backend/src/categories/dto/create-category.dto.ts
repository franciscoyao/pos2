import { IsString, IsInt, IsOptional, IsIn } from 'class-validator';

export class CreateCategoryDto {
  @IsString()
  name: string;

  @IsString()
  @IsIn(['dine-in', 'takeaway'])
  menuType: string;

  @IsInt()
  @IsOptional()
  sortOrder?: number;

  @IsString()
  @IsOptional()
  station?: string;

  @IsString()
  @IsOptional()
  status?: string;
}
