<?php

namespace Kalnoy\Cruddy\Schema;

use Kalnoy\Cruddy\Entity;

/**
 * Instance factory connects attribute collection, entity and actual factory.
 *
 * @since 1.0.0
 */
class InstanceFactory {

    /**
     * The factory.
     *
     * @var BaseFactory
     */
    protected $factory;

    /**
     * The entity.
     *
     * @var Entity
     */
    protected $entity;

    /**
     * The collection to where attributes are placed.
     *
     * @var BaseCollection
     */
    protected $collection;

    /**
     * Init instance factory.
     *
     * @param BaseFactory    $factory
     * @param Entity         $entity
     * @param BaseCollection $collection
     */
    public function __construct(BaseFactory $factory, Entity $entity, BaseCollection $collection)
    {
        $this->factory = $factory;
        $this->entity = $entity;
        $this->collection = $collection;
    }

    /**
     * Try to resolve macro.
     *
     * @param string $method
     * @param array  $parameters
     *
     * @return AttributeInterface
     */
    public function __call($method, $parameters)
    {
        return $this->factory->resolve($method, $this->entity, $this->collection, $parameters);
    }
}