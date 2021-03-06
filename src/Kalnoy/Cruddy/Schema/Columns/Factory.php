<?php

namespace Kalnoy\Cruddy\Schema\Columns;

use Kalnoy\Cruddy\Schema\BaseFactory;

/**
 * The column factory.
 *
 * @since 1.0.0
 */
class Factory extends BaseFactory {

    /**
     * @var array
     */
    protected $macros =
    [
        'states' => 'Kalnoy\Cruddy\Schema\Columns\Types\States',
    ];

    /**
     * Create computed column.
     *
     * @param \Kalnoy\Cruddy\Entity $entity
     * @param Collection            $collection
     * @param int                   $id
     * @param \Closure              $value
     *
     * @return Types\Computed
     */
    public function compute($entity, $collection, $id, \Closure $value)
    {
        $instance = new Types\Computed($entity, $id, $value);

        $collection->add($instance);

        return $instance;
    }

    /**
     * Create new proxy column.
     *
     * @param \Kalnoy\Cruddy\Entity $entity
     * @param Collection            $collection
     * @param string                $id
     *
     * @return Types\Proxy
     */
    public function col($entity, $collection, $id)
    {
        $field = $entity->getFields()->get($id);

        if ($field === null)
        {
            throw new \RuntimeException("The field with an id of {$id} is not found.");
        }

        $instance = new Types\Proxy($entity, $id, $field);

        $collection->add($instance);

        return $instance;
    }

}