import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const GetUser = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user;
    if (!user) return null;

    if (data === 'id' && !user.id && user.userId) {
      return user.userId;
    }
    if (data === 'userId' && !user.userId && user.id) {
      return user.id;
    }

    return data ? user[data] : user;
  },
);
