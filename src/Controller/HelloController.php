<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

final class HelloController
{
    #[Route('/', name: 'hello')]
    public function __invoke(): Response
    {
        return new Response('Hello World 👋 (Symfony + FrankenPHP)');
    }
}
